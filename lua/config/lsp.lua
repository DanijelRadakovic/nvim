-- Native LSP (nvim 0.11+). Language servers are declared in lua/lang/*.lua, one file per language, each
-- returning a list of { server, cmd, filetypes, root_markers, settings }. Servers are taken from the system
-- PATH; one that isn't installed is silently skipped. Project-specific overrides go through
-- vim.lsp.config() in the projects repo (see config/projects.lua).
local specs = {}
for _, file in ipairs(vim.fn.glob(vim.fn.stdpath("config") .. "/lua/lang/*.lua", false, true)) do
  local ok, list = pcall(require, "lang." .. vim.fn.fnamemodify(file, ":t:r"))
  if ok then vim.list_extend(specs, list) else vim.notify(tostring(list), vim.log.levels.ERROR) end
end

for _, s in ipairs(specs) do
  vim.lsp.config(s.server, {
    cmd = s.cmd, filetypes = s.filetypes, root_markers = s.root_markers, settings = s.settings,
  })
end

-- Enable lazily, on first matching filetype: by then project overrides have been applied, and we can check
-- that the (possibly overridden) executable exists.
local enabled = {}
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    for _, s in ipairs(specs) do
      if not enabled[s.server] and vim.tbl_contains(s.filetypes, ev.match) then
        local cmd = vim.lsp.config[s.server].cmd
        if type(cmd) ~= "table" or vim.fn.executable(cmd[1]) == 1 then
          enabled[s.server] = true
          vim.lsp.enable(s.server)
        end
      end
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local m = function(lhs, rhs, d) vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = d }) end
    local tb = function(f) return function() require("telescope.builtin")[f]() end end
    m("gd", vim.lsp.buf.definition, "Definition")
    m("gD", vim.lsp.buf.declaration, "Declaration")
    m("gr", tb("lsp_references"), "References")
    m("gi", tb("lsp_implementations"), "Implementations")
    m("K", vim.lsp.buf.hover, "Hover")
    m("<leader>rn", vim.lsp.buf.rename, "Rename")
    m("<leader>ca", vim.lsp.buf.code_action, "Code action")
    m("<leader>ss", tb("lsp_document_symbols"), "Document symbols")
    m("<leader>sS", tb("lsp_dynamic_workspace_symbols"), "Workspace symbols")
    m("<leader>h", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
    end, "Toggle inlay hints")
    -- .hpp <-> .cpp (clangd extension)
    m("<leader>o", function()
      local c = vim.lsp.get_clients({ bufnr = ev.buf, name = "clangd" })[1]
      if not c then return end
      c:request("textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(ev.buf), function(_, r)
        if r then vim.cmd.edit(vim.uri_to_fname(r)) else vim.notify("No matching source/header") end
      end, ev.buf)
    end, "Switch header/source")
  end,
})

-- Lint (<leader>l), the same for every language: ask each attached LSP client to apply its "source.fixAll"
-- code action (ruff, eslint, rust-analyzer, ...), format the buffer, then list the remaining diagnostics in the
-- location list. What actually runs depends on the servers/formatters configured in lua/lang/*.lua and on
-- project files such as .clang-format or pyproject.toml.
local function lint()
  local buf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = buf })
  if #clients == 0 then return vim.notify("Lint: no language server attached") end

  for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf, method = "textDocument/codeAction" })) do
    local params = vim.lsp.util.make_range_params(0, c.offset_encoding)
    params.context = { only = { "source.fixAll" }, diagnostics = {} }
    local res = c:request_sync("textDocument/codeAction", params, 3000, buf)
    for _, action in ipairs(res and res.result or {}) do
      if not action.edit and c:supports_method("codeAction/resolve") then
        local r = c:request_sync("codeAction/resolve", action, 3000, buf)
        action = r and r.result or action
      end
      if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, c.offset_encoding) end
      if action.command then c:exec_cmd(action.command, { bufnr = buf }) end
    end
  end

  if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) > 0 then
    vim.lsp.buf.format({ bufnr = buf, timeout_ms = 3000 })
  end

  if #vim.diagnostic.get(buf) > 0 then
    vim.diagnostic.setloclist({ open = true })
  else
    vim.cmd("lclose")
    vim.notify("Lint: no diagnostics")
  end
end
vim.keymap.set("n", "<leader>l", lint, { desc = "Lint (auto-fix, format, list diagnostics)" })

-- Format on save is OFF by default (a repo may have no formatter config). A project turns it on with
--   vim.g.format_on_save = true                  -- every filetype that has an LSP formatter
--   vim.g.format_on_save = { "c", "cpp", "rust" } -- only these filetypes
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(ev)
    local opt = vim.g.format_on_save
    if not opt then return end
    if type(opt) == "table" and not vim.tbl_contains(opt, vim.bo[ev.buf].filetype) then return end
    if #vim.lsp.get_clients({ bufnr = ev.buf, method = "textDocument/formatting" }) == 0 then return end
    vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
  end,
})

vim.diagnostic.config({ virtual_text = { spacing = 2 }, severity_sort = true })
