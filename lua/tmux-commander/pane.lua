local M = {}

-- Get list of all tmux panes in current window with their status
function M.list_panes()
  local result = vim.fn.system("tmux list-panes -F '#{pane_index}:#{pane_current_command}'")
  if vim.v.shell_error ~= 0 then
    return nil, "Failed to list tmux panes"
  end

  local panes = {}
  for line in result:gmatch("[^\r\n]+") do
    local index, cmd = line:match("(%d+):(.+)")
    if index and cmd then
      table.insert(panes, {
        index = tonumber(index),
        command = cmd,
      })
    end
  end

  return panes
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

-- Find first idle pane or create new one in current window
function M.find_or_create_pane(idle_shells)
  local panes, err = M.list_panes()
  if not panes then
    return nil, err
  end

  -- Find first idle pane
  for _, pane in ipairs(panes) do
    if M.is_idle_shell(pane.command, idle_shells) then
      return pane.index
    end
  end

  -- No idle pane found, create new one (split vertically)
  local result = vim.fn.system("tmux split-window -h -dP -F '#{pane_index}'")
  if vim.v.shell_error ~= 0 then
    return nil, "Failed to create new pane"
  end

  local pane_index = tonumber(result:match("%d+"))
  return pane_index
end

-- Send command to specific pane in current window
function M.send_command(pane_index, cmd)
  local escaped_cmd = cmd:gsub("'", "'\\''")
  local result = vim.fn.system(string.format("tmux send-keys -t %d '%s' Enter", pane_index, escaped_cmd))
  if vim.v.shell_error ~= 0 then
    return false, "Failed to send command to pane"
  end
  return true
end

-- Get pane's current command (to check if still running)
function M.get_pane_command(pane_index)
  local result = vim.fn.system(string.format("tmux display -pt %d '#{pane_current_command}'", pane_index))
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.trim(result)
end

-- Jump to pane
function M.focus_pane(pane_index)
  vim.fn.system(string.format("tmux select-pane -t %d", pane_index))
end

return M
