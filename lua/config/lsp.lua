-- Native LSP (nvim 0.11+). clangd reads the repo's .clangd (generated from .clangd.in by CMake),
-- which already holds the per-directory flags for device kernels, so no extra flags here.
local clangd = vim.fn.exepath("clangd-20") ~= "" and "clangd-20" or "clangd"

vim.lsp.config("clangd", {
  cmd = {
    clangd,
    "--background-index",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders=false",
    "--clang-tidy=false", -- repo has no .clang-tidy
    "-j=8",
  },
  filetypes = { "c", "cpp" },
  root_markers = { ".clangd", ".clangd.in", ".clang-format", "CMakePresets.json", ".git" },
})
vim.lsp.enable("clangd")

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
    m("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format (uses .clang-format)")
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

-- Format C/C++ on save with clangd, which uses the repo's .clang-format (InsertBraces etc.)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.cpp", "*.hpp", "*.h", "*.c" },
  callback = function() vim.lsp.buf.format({ timeout_ms = 2000 }) end,
})

vim.diagnostic.config({ virtual_text = { spacing = 2 }, severity_sort = true })
