local nerd = vim.g.have_nerd_font

return {
  { "folke/tokyonight.nvim", priority = 1000,
    config = function() vim.cmd.colorscheme("tokyonight-night") end },

  { "nvim-treesitter/nvim-treesitter", branch = "master", build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    init = function()
      -- nvim-treesitter `master` registers markdown-injection directives that expect a single node per
      -- capture; Neovim 0.12 passes a list, which crashes ("attempt to call method 'range' (a nil value)").
      -- Re-register 0.12-compatible versions once the plugin has loaded.
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyLoad",
        callback = function(ev)
          if ev.data ~= "nvim-treesitter" then return end
          pcall(require, "nvim-treesitter.query_predicates")
          local q = vim.treesitter.query
          local function node_of(match, id)
            local n = match[id]
            if type(n) == "table" then n = n[#n] end
            return n
          end
          local function text(match, id, bufnr)
            local n = node_of(match, id)
            return n and vim.treesitter.get_node_text(n, bufnr) or nil
          end
          q.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
            local t = text(match, pred[2], bufnr)
            if not t then return end
            t = t:lower()
            metadata["injection.language"] = vim.treesitter.language.get_lang(t) or t
          end, { force = true, all = true })
          q.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
            local t = text(match, pred[2], bufnr)
            if not t then return end
            local parts = vim.split(t, "/", {})
            metadata["injection.language"] = parts[#parts]
          end, { force = true, all = true })
          q.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
            local id = pred[2]
            local n = node_of(match, id)
            if not n then return end
            local t = vim.treesitter.get_node_text(n, bufnr, { metadata = metadata[id] }) or ""
            metadata[id] = metadata[id] or {}
            metadata[id].text = t:lower()
          end, { force = true, all = true })
        end,
      })
    end,
    opts = {
      -- cpp for kernels/host code, cmake for CMakeLists, python for the analyze.py scripts
      ensure_installed = { "c", "cpp", "cmake", "python", "bash", "yaml", "json", "markdown",
        "markdown_inline", "lua", "vim", "vimdoc", "diff", "gitcommit" },
      highlight = { enable = true },
      indent = { enable = true },
    } },

  { "nvim-telescope/telescope.nvim", branch = "master", dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
      { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Changed files (with diff preview)" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
      { "<leader>fk", function() require("telescope.builtin").find_files({ cwd = "src/operations", prompt_title = "Operations / kernels" }) end, desc = "Operations & kernels" },
      { "<leader>ft", function() require("telescope.builtin").find_files({ cwd = "tests" }) end, desc = "Tests" },
      { "<leader>fT", function() require("telescope.builtin").find_files({ cwd = "tools" }) end, desc = "Tools / benches" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          -- ignore the huge generated benchmark CSVs and build dirs
          file_ignore_patterns = { "^%.build/", "^%.cache/", "^%.tt%-metal%-build", "^generated/", "/results/raw/" },
        },
      })
      pcall(require("telescope").load_extension, "fzf")
    end },

  { "hrsh7th/nvim-cmp", event = "InsertEnter", dependencies = {
      "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = { { name = "nvim_lsp" }, { name = "path" }, { name = "buffer" } },
      })
      vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })
    end },

  { "lewis6991/gitsigns.nvim", opts = {
      on_attach = function(b)
        local gs = require("gitsigns")
        vim.keymap.set("n", "]c", function() gs.nav_hunk("next") end, { buffer = b })
        vim.keymap.set("n", "[c", function() gs.nav_hunk("prev") end, { buffer = b })
        vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = b, desc = "Preview hunk" })
        vim.keymap.set("n", "<leader>gb", gs.blame_line, { buffer = b, desc = "Blame line" })
      end } },

  { "nvim-lualine/lualine.nvim",
    opts = { options = { theme = "tokyonight", icons_enabled = nerd and true or false } } },
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>t", "<cmd>NvimTreeToggle<cr>", desc = "File tree" },
      { "<leader>T", "<cmd>NvimTreeFindFile<cr>", desc = "Reveal current file in tree" },
    },
    opts = {
      view = { width = 35 },
      -- ASCII icons: no Nerd Font needed (missing glyphs show up as "?" boxes)
      renderer = {
        highlight_git = "name",
        icons = {
          show = { file = nerd, folder = nerd, folder_arrow = true, git = false },
          glyphs = nerd and nil or {
            folder = { arrow_closed = ">", arrow_open = "v" },
            git = { unstaged = "M", staged = "S", unmerged = "!", renamed = "R",
                    untracked = "U", deleted = "D", ignored = "." },
          },
        },
      },
      -- h = collapse folder / go to parent, l = expand folder / open file
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        local o = function(d) return { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = d } end
        vim.keymap.set("n", "h", api.node.navigate.parent_close, o("Collapse folder"))
        vim.keymap.set("n", "l", api.node.open.edit, o("Expand folder / open file"))
      end,
      git = { enable = true, ignore = false },
      filters = { custom = { "^\\.git$", "^\\.build$", "^\\.cache$" } },
    } },
  { "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff all changes" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "History of this file" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
    } },
  { "MeanderingProgrammer/render-markdown.nvim", ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    keys = { { "<leader>mp", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering" } },
    opts = { code = { sign = false }, heading = { sign = false } } },
  { "stevearc/oil.nvim", opts = {}, keys = { { "-", "<cmd>Oil<cr>", desc = "File explorer" } } },
}
