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
  local history = require("tmux-commander.history")
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
  local window = require("tmux-commander.window")
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
