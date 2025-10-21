local M = {}

-- Get list of all tmux windows with their status
function M.list_windows()
  local result = vim.fn.system("tmux list-windows -F '#{window_index}:#{pane_current_command}'")
  if vim.v.shell_error ~= 0 then
    return nil, "Failed to list tmux windows"
  end

  local windows = {}
  for line in result:gmatch("[^\r\n]+") do
    local index, cmd = line:match("(%d+):(.+)")
    if index and cmd then
      table.insert(windows, {
        index = tonumber(index),
        command = cmd,
      })
    end
  end

  return windows
end

-- Check if a command is an idle shell
function M.is_idle_shell(cmd, idle_shells)
  for _, shell in ipairs(idle_shells) do
    if cmd == shell then
      return true
    end
  end
  return false
end

-- Find first idle window or create new one
function M.find_or_create_window(idle_shells)
  local windows, err = M.list_windows()
  if not windows then
    return nil, err
  end

  -- Find first idle window
  for _, win in ipairs(windows) do
    if M.is_idle_shell(win.command, idle_shells) then
      return win.index
    end
  end

  -- No idle window found, create new one
  local result = vim.fn.system("tmux new-window -dP -F '#{window_index}'")
  if vim.v.shell_error ~= 0 then
    return nil, "Failed to create new window"
  end

  local window_index = tonumber(result:match("%d+"))
  return window_index
end

-- Send command to specific window
function M.send_command(window_index, cmd)
  local escaped_cmd = cmd:gsub("'", "'\\''")
  local result = vim.fn.system(string.format("tmux send-keys -t :%d '%s' Enter", window_index, escaped_cmd))
  if vim.v.shell_error ~= 0 then
    return false, "Failed to send command to window"
  end
  return true
end

-- Get window's current command (to check if still running)
function M.get_window_command(window_index)
  local result = vim.fn.system(string.format("tmux display -pt :%d '#{pane_current_command}'", window_index))
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.trim(result)
end

-- Jump to window
function M.focus_window(window_index)
  vim.fn.system(string.format("tmux select-window -t :%d", window_index))
end

return M
