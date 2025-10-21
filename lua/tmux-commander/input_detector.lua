local M = {}

-- Capture the last few lines from a tmux pane
-- @param target string Target identifier (window or pane)
-- @param is_window boolean True if target is a window, false if it's a pane
-- @return string|nil Captured content or nil on error
function M.capture_pane_content(target, is_window)
  local cmd
  if is_window then
    cmd = string.format("tmux capture-pane -t :%s -p -S -10", target)
  else
    cmd = string.format("tmux capture-pane -t %s -p -S -10", target)
  end
  
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  
  return vim.trim(result)
end

-- Check if content matches any input prompt patterns
-- @param content string Content to check
-- @param patterns table List of pattern definitions with { pattern, password }
-- @return table|nil Match info { pattern, password, prompt_text } or nil
function M.detect_input_prompt(content, patterns)
  if not content or content == "" then
    return nil
  end
  
  -- Get the last few lines (most likely to have prompts)
  local lines = vim.split(content, "\n")
  local last_lines = {}
  local start_idx = math.max(1, #lines - 5)
  for i = start_idx, #lines do
    table.insert(last_lines, lines[i])
  end
  
  -- Check each line against patterns
  for _, line in ipairs(last_lines) do
    for _, pattern_def in ipairs(patterns) do
      if line:match(pattern_def.pattern) then
        return {
          pattern = pattern_def.pattern,
          password = pattern_def.password,
          prompt_text = vim.trim(line),
        }
      end
    end
  end
  
  return nil
end

-- Show input prompt to user and send response to tmux
-- @param target string Target identifier (window or pane)
-- @param is_window boolean True if target is a window, false if it's a pane
-- @param match_info table Match info from detect_input_prompt
function M.prompt_and_send(target, is_window, match_info)
  local target_type = is_window and "window" or "pane"
  local prompt_message = string.format("Input needed in tmux %s %s: %s", target_type, target, match_info.prompt_text)
  
  -- Create input options
  local input_opts = {
    prompt = prompt_message,
  }
  
  -- Use secure input for passwords (Neovim 0.10+)
  if match_info.password and vim.fn.has("nvim-0.10") == 1 then
    input_opts.default = ""
    -- Note: vim.ui.input doesn't have a native password mode yet in 0.9
    -- Users on 0.10+ can use plugins that support this
  end
  
  vim.ui.input(input_opts, function(input)
    if not input then
      -- User cancelled
      return
    end
    
    -- Escape single quotes in input
    local escaped_input = input:gsub("'", "'\\''")
    
    -- Send to tmux
    local send_cmd
    if is_window then
      send_cmd = string.format("tmux send-keys -t :%s '%s' Enter", target, escaped_input)
    else
      send_cmd = string.format("tmux send-keys -t %s '%s' Enter", target, escaped_input)
    end
    
    vim.fn.system(send_cmd)
    
    if vim.v.shell_error ~= 0 then
      vim.notify(
        string.format("Failed to send input to tmux %s %s", target_type, target),
        vim.log.levels.ERROR
      )
    end
  end)
end

return M
