local M = {}

M.config = {
  notification = true,
  monitor_interval = 2000,
  idle_shells = { "zsh", "bash", "sh", "fish" },
  notify_on = {
    start = true,
    success = true,
    failure = true,
  },
  history = {
    enabled = true,
    max_entries = 100,
  },
  commands = {}, -- Simple key-value: { deploy = "kamal deploy" }
}

-- Setup function called by lazy.nvim
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Load submodules
  local history = require("tmux-runner.history")
  local commands = require("tmux-runner.commands")

  -- Initialize history
  history.init(M.config.history)

  -- Store commands
  commands.set_commands(M.config.commands)
end

-- Public API functions

-- Run a named command from config
function M.run(name)
  local commands = require("tmux-runner.commands")
  commands.run(name, M.config)
end

-- Prompt for command and run
function M.run_prompt()
  local cmd = vim.fn.input("Command: ")
  if cmd and cmd ~= "" then
    local commands = require("tmux-runner.commands")
    commands.run_custom(cmd, M.config)
  end
end

-- Show command history
function M.show_history()
  local history = require("tmux-runner.history")
  local entries = history.get()

  if #entries == 0 then
    vim.notify("No command history", vim.log.levels.INFO)
    return
  end

  -- TODO: Add telescope/fzf picker
  vim.notify(string.format("Command history has %d entries", #entries), vim.log.levels.INFO)
end

-- Repeat last command
function M.repeat_last()
  local commands = require("tmux-runner.commands")
  commands.repeat_last(M.config)
end

-- Jump to active runner window
function M.inspect()
  local monitor = require("tmux-runner.monitor")
  for window_index, _ in pairs(monitor.active_monitors) do
    local window = require("tmux-runner.window")
    window.focus_window(window_index)
    return
  end
  vim.notify("No active runner window", vim.log.levels.WARN)
end

-- Kill running command
function M.kill()
  local monitor = require("tmux-runner.monitor")
  for window_index, _ in pairs(monitor.active_monitors) do
    monitor.kill(window_index)
    vim.notify("Killed command in window " .. window_index, vim.log.levels.INFO)
    return
  end
  vim.notify("No running command to kill", vim.log.levels.WARN)
end

-- List all tmux windows
function M.list_windows()
  local window = require("tmux-runner.window")
  local windows, err = window.list_windows()

  if not windows then
    vim.notify("Failed to list windows: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  local lines = {}
  for _, win in ipairs(windows) do
    table.insert(lines, string.format("Window %d: %s", win.index, win.command))
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M
