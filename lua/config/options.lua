local o = vim.opt
o.number, o.relativenumber = true, true
o.signcolumn = "yes"
o.cursorline = true
o.termguicolors = true
o.mouse = "a"
o.clipboard = "unnamedplus"
o.undofile = true
o.ignorecase, o.smartcase = true, true
o.scrolloff = 8
o.splitright, o.splitbelow = true, true
o.updatetime = 250
o.completeopt = { "menu", "menuone", "noselect" }
-- Match the project's .clang-format: 4 spaces, no tabs, 120 columns
o.expandtab, o.shiftwidth, o.tabstop, o.softtabstop = true, 4, 4, 4
o.colorcolumn = "120"
o.exrc = true -- allow trusted project-local .nvim.lua

-- clangd config files are YAML
vim.filetype.add({
  filename = { [".clangd"] = "yaml", [".clangd.in"] = "yaml", [".clang-format"] = "yaml" },
  pattern = { ["CMakePresets%.json"] = "jsonc" },
})
-- Compile-time pound-defines in tt-metal kernels are plain C++
vim.api.nvim_create_autocmd("TextYankPost", { callback = function() vim.hl.on_yank() end })

-- Set to true after installing a Nerd Font in your *terminal* (e.g. JetBrainsMono Nerd Font)
-- and selecting it in the terminal's font settings. Enables file/folder icons.
vim.g.have_nerd_font = true

-- Remote/headless machines have no system clipboard tool: copy through the terminal with OSC 52 so `y` reaches the Mac clipboard.
-- (Needs a terminal that supports OSC 52, e.g. iTerm2 with "Applications in terminal may access clipboard".)
local has_provider = vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1
  or vim.fn.executable("wl-copy") == 1
if not has_provider then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
