local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map("n", "<C-h>", "<C-w>h"); map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k"); map("n", "<C-l>", "<C-w>l")
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>q", vim.diagnostic.setqflist, { desc = "Diagnostics to quickfix" })

-- Quit everything at once
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>W", "<cmd>wqa<cr>", { desc = "Save all and quit" })
-- Don't get stuck with only the file tree left open after closing the last file
vim.api.nvim_create_autocmd("BufEnter", {
  nested = true,
  callback = function()
    local wins = vim.api.nvim_list_wins()
    if #wins == 1 and vim.bo.filetype == "NvimTree" then vim.cmd("quit") end
  end,
})

-- Show diagnostics in full: toggle multi-line inline text (virtual_lines) vs. the short one-liner
local full = false
map("n", "<leader>dl", function()
  full = not full
  vim.diagnostic.config({ virtual_lines = full and { current_line = true } or false, virtual_text = not full and { spacing = 2 } or false })
end, { desc = "Toggle full inline diagnostics" })
map("n", "<leader>dL", function()
  full = true
  vim.diagnostic.config({ virtual_lines = true, virtual_text = false })
end, { desc = "Full diagnostics on all lines" })

-- Toggle the quickfix list (diagnostics, build errors, grep results)
map("n", "<leader>xq", function()
  local open = vim.fn.getqflist({ winid = 0 }).winid ~= 0
  vim.cmd(open and "cclose" or "copen")
end, { desc = "Toggle quickfix" })
-- `q` closes the quickfix window when focused
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(ev) vim.keymap.set("n", "q", "<cmd>cclose<cr>", { buffer = ev.buf, silent = true }) end,
})

-- Terminal split at the bottom (uses $SHELL; zsh if you install it and chsh / set `vim.o.shell`)
-- Multiple terminals: <leader>tn new, <leader>ts pick one, <leader>t1..t9 jump to Nth, <leader>tt last used
local last_term
local function terms()
  local r = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "terminal" then r[#r + 1] = b end
  end
  return r
end
-- Terminals take over the current window (like a full-screen VS Code terminal), no split.
local function target_win()
  if vim.bo.filetype ~= "NvimTree" then return vim.api.nvim_get_current_win() end
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype ~= "NvimTree" then return w end
  end
end
local last_code
local function remember_code()
  local b = vim.api.nvim_get_current_buf()
  if vim.bo[b].buftype == "" then last_code = b end
end
local function show(buf)
  remember_code()
  local w = target_win()
  if w then vim.api.nvim_set_current_win(w) end
  vim.api.nvim_win_set_buf(0, buf)
  last_term = buf
  vim.cmd("startinsert")
end
local function new_term()
  remember_code()
  local w = target_win()
  if w then vim.api.nvim_set_current_win(w) end
  vim.cmd("enew | terminal")
  last_term = vim.api.nvim_get_current_buf()
  vim.cmd("startinsert")
end
-- Back to the file you were editing
map("n", "<leader>tb", function()
  if last_code and vim.api.nvim_buf_is_valid(last_code) then vim.api.nvim_set_current_buf(last_code)
  else vim.cmd("bprevious") end
end, { desc = "Back to code from terminal" })
map("n", "<leader>tn", new_term, { desc = "New terminal" })
map("n", "<leader>tt", function()
  if last_term and vim.api.nvim_buf_is_valid(last_term) then show(last_term)
  elseif terms()[1] then show(terms()[1])
  else new_term() end
end, { desc = "Open / focus last terminal" })
map("n", "<leader>ts", function()
  local list = terms()
  if #list == 0 then return new_term() end
  vim.ui.select(list, {
    prompt = "Terminal",
    format_item = function(b)
      local n = vim.fn.index(list, b) + 1
      local title = vim.b[b].term_title or ""
      return ("%d: %s"):format(n, title)
    end,
  }, function(b) if b then show(b) end end)
end, { desc = "Select terminal" })
for i = 1, 9 do
  map("n", "<leader>t" .. i, function()
    local b = terms()[i]
    if b then show(b) else vim.notify("No terminal " .. i) end
  end, { desc = "Terminal " .. i })
end
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })
vim.api.nvim_create_autocmd("TermOpen", { callback = function() vim.wo.number, vim.wo.relativenumber = false, false end })

