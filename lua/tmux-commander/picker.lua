-- lua/tmux-commander/picker.lua
-- Picker utilities for tmux-commander.nvim using Snacks.nvim

local M = {}

local picker = require("snacks.picker")
local history_mod = require("tmux-commander.history")
local tmux_mod = require("tmux-commander.tmux")

-----------------------------------------------------------------------
-- Show tmux command history picker
-----------------------------------------------------------------------
function M.show_history()
	local items = history_mod.get()
	if not items or #items == 0 then
		vim.notify("No tmux command history.", vim.log.levels.INFO)
		return
	end

	-- newest first
	table.sort(items, function(a, b)
		return (a.timestamp or 0) > (b.timestamp or 0)
	end)

	-- Add text field for display
	for _, item in ipairs(items) do
		local cmd = item.command or "Unknown Command"
		local time_str = item.timestamp and os.date("%H:%M:%S", item.timestamp) or "??:??:??"
		local status_icon = item.exit_code == 0 and "✓" or (item.exit_code == nil and "⏱" or "✗")
		item.text = string.format("%s %s [%s]", status_icon, cmd, time_str)
	end

	picker.pick({
		items = items,
		prompt = "Tmux History > ",
		layout = { preset = "ivy" },
		confirm = function(picker, item)
			if item and item.command then
				picker:close()
				require("tmux-commander").run_prompt(item.command)
			end
		end,
	})
end

-----------------------------------------------------------------------
-- Adopt all running windows in the session
-----------------------------------------------------------------------
function M.show_adopt()
	local windows = tmux_mod.list_windows()
	local monitor = require("tmux-commander.monitor")
	local config = require("tmux-commander").config
	local commands = require("tmux-commander.commands")

	if #windows == 0 then
		vim.notify("No tmux windows found.", vim.log.levels.WARN)
		return
	end

	local adopted_count = 0
	local already_monitored = 0
	local idle_count = 0

	for _, win in ipairs(windows) do
		-- Check if already monitored
		if monitor.active_monitors[win.id] then
			already_monitored = already_monitored + 1
		else
			-- Check if idle shell
			local is_idle = false
			for _, shell in ipairs(config.idle_shells or { "zsh", "bash", "sh" }) do
				if win.command == shell then
					is_idle = true
					idle_count = idle_count + 1
					break
				end
			end

			-- Adopt if not idle
			if not is_idle then
				commands.adopt_window(win.id, config)
				adopted_count = adopted_count + 1
			end
		end
	end

	-- Show summary notification
	local msg_parts = {}
	if adopted_count > 0 then
		table.insert(msg_parts, string.format("Adopted %d window%s", adopted_count, adopted_count == 1 and "" or "s"))
	end
	if already_monitored > 0 then
		table.insert(
			msg_parts,
			string.format("%d already monitored", already_monitored)
		)
	end
	if idle_count > 0 then
		table.insert(msg_parts, string.format("%d idle", idle_count))
	end

	local summary = table.concat(msg_parts, ", ")
	if adopted_count > 0 then
		vim.notify("✓ " .. summary, vim.log.levels.INFO)
	else
		vim.notify("No new windows to adopt (" .. summary .. ")", vim.log.levels.WARN)
	end
end

-----------------------------------------------------------------------
-- Show windows of the current tmux session
-----------------------------------------------------------------------
function M.show_windows()
	local windows = tmux_mod.list_windows()
	if #windows == 0 then
		vim.notify("No tmux windows in current session.", vim.log.levels.INFO)
		return
	end

	picker.pick({
		items = windows,
		prompt = "Tmux Windows > ",
		format = function(item)
			local active_marker = item.active and "*" or " "
			return {
				{ string.format("%s [%d] %s - %s", active_marker, item.id, item.name, item.command) },
			}
		end,
		preview = function(ctx)
			local item = ctx.item
			if not item or not item.id then
				return false
			end
			local content = tmux_mod.get_window_content(item.id)
			local lines = vim.split(content, "\n")

			if not ctx.buf then
				ctx.buf = vim.api.nvim_create_buf(false, true)
			end

			vim.bo[ctx.buf].modifiable = true
			vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
			vim.bo[ctx.buf].filetype = "text"
			vim.bo[ctx.buf].modifiable = false

			if ctx.win and vim.api.nvim_win_is_valid(ctx.win) then
				vim.api.nvim_win_set_buf(ctx.win, ctx.buf)
			end

			return true
		end,
		confirm = function(picker_obj, item)
			if item and item.id then
				picker_obj:close()
				tmux_mod.switch_window(item.id)
			end
		end,
	})
end

return M
