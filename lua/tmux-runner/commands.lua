local M = {}

M.registry = {}
M.last_command = nil

-- Register all commands and create keymaps
function M.register(commands, prefix)
  for _, cmd_config in ipairs(commands) do
    M.registry[cmd_config.name] = cmd_config

    -- Create keymap
    local keymap = prefix .. cmd_config.key
    vim.keymap.set("n", keymap, function()
      M.run(cmd_config.name)
    end, { desc = cmd_config.desc })
  end

  -- Register built-in commands
  M.register_builtin(prefix)
end

-- Register built-in utility commands
function M.register_builtin(prefix)
  -- History
  vim.api.nvim_create_user_command("SmartRunnerHistory", function()
    M.show_history()
  end, {})

  -- Repeat last
  vim.api.nvim_create_user_command("SmartRunnerRepeat", function()
    M.repeat_last()
  end, {})

  -- Inspect
  vim.api.nvim_create_user_command("SmartRunnerInspect", function()
    M.inspect()
  end, {})

  -- Kill
  vim.api.nvim_create_user_command("SmartRunnerKill", function()
    M.kill()
  end, {})

  -- List
  vim.api.nvim_create_user_command("SmartRunnerList", function()
    M.list()
  end, {})
end

-- Run a command by name
function M.run(name)
  local cmd_config = M.registry[name]
  if not cmd_config then
    vim.notify("Command not found: " .. name, vim.log.levels.ERROR)
    return
  end

  local window = require("tmux-runner.window")
  local monitor = require("tmux-runner.monitor")
  local config = require("tmux-runner").config

  -- Get command string
  local cmd
  if type(cmd_config.cmd) == "function" then
    cmd = cmd_config.cmd()
  else
    cmd = cmd_config.cmd
  end

  if not cmd or cmd == "" then
    return
  end

  -- Confirm if needed
  local opts = cmd_config.opts or {}
  if opts.confirm then
    local response = vim.fn.input(string.format("Run '%s'? (y/n): ", cmd))
    if response:lower() ~= "y" then
      return
    end
  end

  -- Find or create window
  local window_index, err = window.find_or_create_window(config.idle_shells)
  if not window_index then
    vim.notify("Failed to find window: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Send command
  local success, send_err = window.send_command(window_index, cmd)
  if not success then
    vim.notify("Failed to send command: " .. (send_err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Focus window if needed
  if opts.focus or opts.interactive then
    window.focus_window(window_index)
  end

  -- Start monitoring
  monitor.start(window_index, cmd, config)

  -- Store as last command
  M.last_command = { name = name, cmd = cmd }
end

-- Show history (placeholder - will add picker later)
function M.show_history()
  local history = require("tmux-runner.history")
  local entries = history.get()

  if #entries == 0 then
    vim.notify("No command history", vim.log.levels.INFO)
    return
  end

  -- For now, just print (TODO: add telescope/fzf picker)
  vim.notify("History has " .. #entries .. " entries", vim.log.levels.INFO)
end

-- Repeat last command
function M.repeat_last()
  if not M.last_command then
    vim.notify("No previous command", vim.log.levels.WARN)
    return
  end

  M.run(M.last_command.name)
end

-- Inspect runner window
function M.inspect()
  local monitor = require("tmux-runner.monitor")
  -- Find first active monitor
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
  -- Find first active monitor
  for window_index, _ in pairs(monitor.active_monitors) do
    monitor.kill(window_index)
    vim.notify("Killed command in window " .. window_index, vim.log.levels.INFO)
    return
  end

  vim.notify("No running command to kill", vim.log.levels.WARN)
end

-- List runner windows
function M.list()
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
