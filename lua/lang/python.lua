local root = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "pyrightconfig.json", ".git" }

return {
  { server = "basedpyright", cmd = { "basedpyright-langserver", "--stdio" }, filetypes = { "python" }, root_markers = root },
  { server = "ruff", cmd = { "ruff", "server" }, filetypes = { "python" }, root_markers = root },
}
