local M = {}

M.config = {}
M.history_file = nil
M.history = {}

function M.init(config)
  M.config = config
  M.history_file = vim.fn.stdpath("data") .. "/tmux-commander-history.json"
  M.load()
end

-- Load history from file
function M.load()
  local file = io.open(M.history_file, "r")
  if not file then
    M.history = {}
    return
  end

  local content = file:read("*a")
  file:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if ok and decoded then
    M.history = decoded
  else
    M.history = {}
  end
end

-- Save history to file
function M.save()
  -- Initialize if not set up
  if not M.history_file then
    M.history_file = vim.fn.stdpath("data") .. "/tmux-commander-history.json"
  end

  -- Limit to max_entries
  local max_entries = (M.config and M.config.max_entries) or 100
  if #M.history > max_entries then
    local start = #M.history - max_entries + 1
    M.history = { unpack(M.history, start) }
  end

  local file = io.open(M.history_file, "w")
  if not file then
    vim.notify("Failed to save command history", vim.log.levels.WARN)
    return
  end

  local encoded = vim.json.encode(M.history)
  file:write(encoded)
  file:close()
end

-- Add command to history
function M.add(cmd, window_index, exit_code, duration)
  table.insert(M.history, {
    command = cmd,
    timestamp = os.time(),
    window = window_index,
    exit_code = exit_code or 0,
    duration = duration or 0,
  })
  M.save()
end

-- Get history entries
function M.get()
  return M.history
end

return M
