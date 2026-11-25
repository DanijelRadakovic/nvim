-- First clangd found: plain `clangd`, else the highest versioned `clangd-N`.
-- A project can pin a specific one (see the projects repo).
local function find_clangd()
  if vim.fn.executable("clangd") == 1 then return "clangd" end
  for v = 30, 14, -1 do
    if vim.fn.executable("clangd-" .. v) == 1 then return "clangd-" .. v end
  end
  return "clangd"
end

return {
  {
    server = "clangd",
    cmd = {
      find_clangd(),
      "--background-index",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders=false",
    },
    filetypes = { "c", "cpp" },
    -- compile flags come from the project's own .clangd / compile_commands.json
    root_markers = { ".clangd", "compile_commands.json", "CMakePresets.json", ".clang-format", ".git" },
  },
}
