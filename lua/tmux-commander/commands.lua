local M = {}

M.last_command = nil
M.last_panel_command = nil

-- Execute a command in a window
function M.run(cmd, config)
  if not cmd or cmd == "" then
    return
  end

  local window = require("tmux-commander.window")
  local monitor = require("tmux-commander.monitor")

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

  -- Start monitoring
  monitor.start_window(window_index, cmd, config)

  -- Store as last command
  M.last_command = cmd
end

-- Execute a command in a pane
function M.run_panel(cmd, config)
  if not cmd or cmd == "" then
    return
  end

  local pane = require("tmux-commander.pane")
  local monitor = require("tmux-commander.monitor")

  -- Find or create pane
  local pane_index, err = pane.find_or_create_pane(config.idle_shells)
  if not pane_index then
    vim.notify("Failed to find pane: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Send command
  local success, send_err = pane.send_command(pane_index, cmd)
  if not success then
    vim.notify("Failed to send command: " .. (send_err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Start monitoring
  monitor.start_pane(pane_index, cmd, config)

  -- Store as last panel command
  M.last_panel_command = cmd
end

-- Repeat last command
function M.repeat_last(config)
  if not M.last_command then
    vim.notify("No previous command", vim.log.levels.WARN)
    return
  end

  M.run(M.last_command, config)
end

-- Adopt an existing window into management
function M.adopt_window(window_index, config)
  local window = require("tmux-commander.window")
  local monitor = require("tmux-commander.monitor")

  -- Get current command running in window
  local current_cmd = window.get_window_command(window_index)
  if not current_cmd then
    vim.notify("Failed to get window command", vim.log.levels.ERROR)
    return
  end

  -- Check if it's an idle shell
  if window.is_idle_shell(current_cmd, config.idle_shells) then
    vim.notify("Window " .. window_index .. " is idle (no command to adopt)", vim.log.levels.WARN)
    return
  end

  -- Start monitoring the window
  monitor.start_window(window_index, current_cmd, config)
  vim.notify("Adopted window " .. window_index .. " running: " .. current_cmd, vim.log.levels.INFO)
end

-- Adopt an existing pane into management
function M.adopt_pane(pane_index, config)
  local pane = require("tmux-commander.pane")
  local monitor = require("tmux-commander.monitor")

  -- Get current command running in pane
  local current_cmd = pane.get_pane_command(pane_index)
  if not current_cmd then
    vim.notify("Failed to get pane command", vim.log.levels.ERROR)
    return
  end

  -- Check if it's an idle shell
  if pane.is_idle_shell(current_cmd, config.idle_shells) then
    vim.notify("Pane " .. pane_index .. " is idle (no command to adopt)", vim.log.levels.WARN)
    return
  end

  -- Start monitoring the pane
  monitor.start_pane(pane_index, current_cmd, config)
  vim.notify("Adopted pane " .. pane_index .. " running: " .. current_cmd, vim.log.levels.INFO)
end

return M
