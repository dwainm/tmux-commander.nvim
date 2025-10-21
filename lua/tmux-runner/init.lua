local M = {}

M.config = {
  notification = true,
  monitor_interval = 2000,
  idle_shells = { "zsh", "bash", "sh", "fish" },
  keymap_prefix = "<leader>r",
  notify_on = {
    start = true,
    success = true,
    failure = true,
  },
  history = {
    enabled = true,
    max_entries = 100,
  },
  commands = {},
}

-- Setup function called by lazy.nvim
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Load submodules
  M.history = require("tmux-runner.history")
  M.window = require("tmux-runner.window")
  M.monitor = require("tmux-runner.monitor")
  M.commands = require("tmux-runner.commands")

  -- Initialize history
  M.history.init(M.config.history)

  -- Register commands
  M.commands.register(M.config.commands, M.config.keymap_prefix)

  vim.notify("tmux-runner.nvim loaded", vim.log.levels.INFO)
end

return M
