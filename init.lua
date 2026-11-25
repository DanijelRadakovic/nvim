vim.g.mapleader = " "
vim.g.maplocalleader = " "
require("config.options")
require("config.keymaps")
require("config.lsp")
require("config.projects").load() -- after lsp (so projects can override it), before plugins load
require("config.lazy")
