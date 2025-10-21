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
}

-- Ensure plugin is initialized
local initialized = false
local function ensure_init()
  if not initialized then
    local history = require("tmux-commander.history")
    history.init(M.config.history)
    initialized = true
  end
end

-- Setup function called by lazy.nvim (optional)
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  ensure_init()
end

-- Public API functions

-- Run a command in a window (prompts if no command provided)
function M.run_prompt(cmd)
  ensure_init()
  if not cmd or cmd == "" then
    cmd = vim.fn.input("Command: ")
  end

  if cmd and cmd ~= "" then
    local commands = require("tmux-commander.commands")
    commands.run(cmd, M.config)
  end
end

-- Run a command in a pane (prompts if no command provided)
function M.run_panel_prompt(cmd)
  ensure_init()
  if not cmd or cmd == "" then
    cmd = vim.fn.input("Command: ")
  end

  if cmd and cmd ~= "" then
    local commands = require("tmux-commander.commands")
    commands.run_panel(cmd, M.config)
  end
end

-- Show command history
function M.show_history()
  ensure_init()
  local picker = require("tmux-commander.picker")
  picker.show_history()
end

-- Repeat last command
function M.repeat_last()
  ensure_init()
  local commands = require("tmux-commander.commands")
  commands.repeat_last(M.config)
end

-- Jump to active runner window
function M.inspect()
  ensure_init()
  local monitor = require("tmux-commander.monitor")
  for window_index, _ in pairs(monitor.active_monitors) do
    local window = require("tmux-commander.window")
    window.focus_window(window_index)
    return
  end
  vim.notify("No active runner window", vim.log.levels.WARN)
end

-- Kill running command
function M.kill()
  ensure_init()
  local monitor = require("tmux-commander.monitor")
  for window_index, _ in pairs(monitor.active_monitors) do
    monitor.kill(window_index)
    vim.notify("Killed command in window " .. window_index, vim.log.levels.INFO)
    return
  end
  vim.notify("No running command to kill", vim.log.levels.WARN)
end

-- List all tmux windows
function M.list_windows()
  ensure_init()
  local picker = require("tmux-commander.picker")
  picker.show_windows()
end

-- Adopt existing window/pane with running command
function M.adopt()
  ensure_init()
  local picker = require("tmux-commander.picker")
  picker.show_adopt()
end

return M
