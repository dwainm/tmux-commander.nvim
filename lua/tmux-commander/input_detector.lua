local M = {}

-- Get cursor position for a tmux target
-- @param target string Target identifier (window or pane)
-- @param is_window boolean True if target is a window, false if it's a pane
-- @return number|nil Cursor X position or nil on error
local function get_cursor_x(target, is_window)
  local cmd
  if is_window then
    cmd = string.format("tmux display-message -t :%s -p '#{cursor_x}'", target)
  else
    cmd = string.format("tmux display-message -t %s -p '#{cursor_x}'", target)
  end

  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end

  return tonumber(vim.trim(result))
end

-- Get current command for a tmux target
-- @param target string Target identifier (window or pane)
-- @param is_window boolean True if target is a window, false if it's a pane
-- @return string|nil Current command or nil on error
local function get_current_command(target, is_window)
  local cmd
  if is_window then
    cmd = string.format("tmux display-message -t :%s -p '#{pane_current_command}'", target)
  else
    cmd = string.format("tmux display-message -t %s -p '#{pane_current_command}'", target)
  end

  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end

  return vim.trim(result)
end

-- Capture the last line from a tmux pane
-- @param target string Target identifier (window or pane)
-- @param is_window boolean True if target is a window, false if it's a pane
-- @return string|nil Last line content or nil on error
local function get_last_line(target, is_window)
  local cmd
  if is_window then
    cmd = string.format("tmux capture-pane -t :%s -p -S -5 | tail -1", target)
  else
    cmd = string.format("tmux capture-pane -t %s -p -S -5 | tail -1", target)
  end

  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end

  return vim.trim(result)
end

-- Check if a command is in the stdin waiters list
-- @param cmd string Command name
-- @param stdin_waiters table Configuration for stdin waiters
-- @return boolean True if command is a known stdin waiter
local function is_stdin_waiter(cmd, stdin_waiters)
  if not stdin_waiters or not stdin_waiters.commands then
    return false
  end

  for _, waiter in ipairs(stdin_waiters.commands) do
    if cmd == waiter then
      return true
    end
  end

  return false
end

-- Check if prompt text matches password patterns
-- @param text string Prompt text to check
-- @param password_patterns table List of password patterns
-- @return boolean True if matches a password pattern
local function is_password_prompt(text, password_patterns)
  if not text or not password_patterns then
    return false
  end

  local lower_text = text:lower()
  for _, pattern in ipairs(password_patterns) do
    if lower_text:find(pattern:lower(), 1, true) then
      return true
    end
  end

  return false
end

-- Detect input state for a tmux target
-- @param target string Target identifier (window or pane)
-- @param is_window boolean True if target is a window, false if it's a pane
-- @param config table Plugin configuration
-- @param idle_shells table List of idle shell names
-- @return table|nil Detection result { state, action, ... } or nil
function M.detect_input_state(target, is_window, config, idle_shells)
  local cursor_x = get_cursor_x(target, is_window)
  local current_cmd = get_current_command(target, is_window)

  if not cursor_x or not current_cmd then
    return nil
  end

  -- Check if idle shell
  local is_idle = false
  for _, shell in ipairs(idle_shells) do
    if current_cmd == shell then
      is_idle = true
      break
    end
  end

  if is_idle then
    return { state = "idle" }
  end

  -- Case 1: Known stdin waiter without prompt (cursor_x == 0)
  if is_stdin_waiter(current_cmd, config.stdin_waiters) and cursor_x == 0 then
    local action = config.stdin_waiters.action or "notify"
    if action == "ignore" then
      return { state = "running" }
    end

    return {
      state = "stdin_waiting",
      action = action,
      cmd = current_cmd,
      target = target,
      is_window = is_window,
    }
  end

  -- Case 2: Cursor mid-line - visible prompt waiting
  if cursor_x > 0 then
    local last_line = get_last_line(target, is_window)
    if last_line and last_line ~= "" then
      local is_password = is_password_prompt(last_line, config.password_patterns)

      return {
        state = "prompt_waiting",
        action = "prompt",
        cmd = current_cmd,
        target = target,
        is_window = is_window,
        prompt_text = last_line,
        is_password = is_password,
      }
    end
  end

  -- Case 3: Running normally
  return { state = "running" }
end

-- Handle detected input state
-- @param detection table Detection result from detect_input_state
function M.handle_input_state(detection)
  if not detection or not detection.action then
    return
  end

  if detection.action == "notify" then
    local target_type = detection.is_window and "window" or "pane"
    vim.notify(
      string.format("⚠️ %s is waiting for input in %s %s\nPress <leader>ri to interact",
        detection.cmd, target_type, detection.target),
      vim.log.levels.WARN
    )
  elseif detection.action == "prompt" then
    M.prompt_and_send(detection)
  end
end

-- Show input prompt to user and send response to tmux
-- @param detection table Detection result with prompt information
function M.prompt_and_send(detection)
  local target_type = detection.is_window and "window" or "pane"
  local prompt_message = string.format(
    "Input for %s (%s %s): %s",
    detection.cmd,
    target_type,
    detection.target,
    detection.prompt_text
  )

  -- Create input options
  local input_opts = {
    prompt = prompt_message,
  }

  -- Note: Password hiding depends on the input UI plugin
  -- vim.ui.input doesn't natively support password mode
  if detection.is_password then
    input_opts.default = ""
  end

  vim.ui.input(input_opts, function(input)
    if not input then
      return
    end

    -- Escape single quotes in input
    local escaped_input = input:gsub("'", "'\\''")

    -- Send to tmux
    local send_cmd
    if detection.is_window then
      send_cmd = string.format("tmux send-keys -t :%s '%s' Enter", detection.target, escaped_input)
    else
      send_cmd = string.format("tmux send-keys -t %s '%s' Enter", detection.target, escaped_input)
    end

    vim.fn.system(send_cmd)

    if vim.v.shell_error ~= 0 then
      vim.notify(
        string.format("Failed to send input to tmux %s %s", target_type, detection.target),
        vim.log.levels.ERROR
      )
    end
  end)
end

return M
