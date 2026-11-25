-- Native LSP only (no rustaceanvim). Install rust-analyzer via rustup: `rustup component add rust-analyzer`.
return {
  {
    server = "rust_analyzer",
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
    settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
  },
}
