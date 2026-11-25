-- Project-specific settings live in <config>/projects/ (~/.config/nvim/projects), which is git-ignored here and is
-- meant to be its own private repo: one Lua file per project. Override the location with $NVIM_PROJECTS_DIR.
--
-- Each file returns:
--   { match = { "^tt%-zkml$" },          -- Lua patterns tested against the git root's directory name and the
--                                        -- `origin` remote's repo name (without .git)
--     setup = function(ctx) ... end }    -- ctx = { root = <git root>, name = <matched name> }
--
-- Settings are read from the directory nvim was started in. The first matching file wins.
local M = {}

local function repo_names(root)
  local names = { vim.fs.basename(root) }
  local out = vim.system({ "git", "-C", root, "remote", "get-url", "origin" }, { text = true }):wait()
  if out.code == 0 then
    local tail = vim.trim(out.stdout):gsub("%.git$", ""):match("[^/:]+$")
    if tail then table.insert(names, tail) end
  end
  return names
end

function M.load()
  local dir = vim.env.NVIM_PROJECTS_DIR or (vim.fn.stdpath("config") .. "/projects")
  if vim.fn.isdirectory(dir) == 0 then return end
  local cwd = vim.fn.getcwd()
  local root = vim.fs.root(cwd, ".git") or cwd
  local names = repo_names(root)

  for _, file in ipairs(vim.fn.sort(vim.fn.glob(dir .. "/*.lua", false, true))) do
    local ok, spec = pcall(dofile, file)
    if not ok then
      vim.notify("Project file " .. file .. ": " .. tostring(spec), vim.log.levels.ERROR)
    elseif type(spec) == "table" and spec.match then
      for _, name in ipairs(names) do
        for _, pat in ipairs(spec.match) do
          if name:match(pat) then
            vim.g.project_name = name
            local sok, err = pcall(spec.setup or function() end, { root = root, name = name })
            if not sok then vim.notify("Project setup " .. file .. ": " .. tostring(err), vim.log.levels.ERROR) end
            return
          end
        end
      end
    end
  end
end

return M
