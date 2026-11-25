-- neocmakelsp: `cargo install neocmakelsp`
return {
  {
    server = "neocmakelsp",
    cmd = { "neocmakelsp", "stdio" },
    filetypes = { "cmake" },
    root_markers = { "CMakePresets.json", "CMakeLists.txt", ".git" },
  },
}
