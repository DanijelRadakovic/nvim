local p = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(p) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", p })
end
vim.opt.rtp:prepend(p)
require("lazy").setup("plugins", { change_detection = { notify = false } })
