local M = {}

local util = require("visual-complexity.util")

local state = {
	win          = nil,
	buf          = nil,
	locations    = {},
	pinned_bufnr = nil,
}

local map_ns = vim.api.nvim_create_namespace("visual_complexity_map")

local function config()
	return require("visual-complexity.config").options
end

local function is_valid_buf(bufnr)
	return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

local function is_valid_win(win)
	return win ~= nil and vim.api.nvim_win_is_valid(win)
end

local function ensure_buffer()
	if is_valid_buf(state.buf) then
		return state.buf
	end

	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(state.buf, "filetype", "visualcomplexitymap")

	local keymaps = (config().keymaps and config().keymaps.map) or {}
	local jump = keymaps.jump or "<CR>"
	local close = keymaps.close or "q"
	local toggle_pin = keymaps.toggle_pin or "p"

	vim.keymap.set("n", jump, function()
		M.jump_to_selection()
	end, { buffer = state.buf, silent = true })

	vim.keymap.set("n", close, function()
		M.close()
	end, { buffer = state.buf, silent = true })

	vim.keymap.set("n", toggle_pin, function()
		M.toggle_pin_for_current_buffer()
	end, { buffer = state.buf, silent = true })

	return state.buf
end

local function ensure_window()
	if is_valid_win(state.win) and vim.api.nvim_win_get_buf(state.win) == state.buf then
		return state.win
	end

	if is_valid_buf(state.buf) then
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win) == state.buf then
				state.win = win
				return win
			end
		end
	end

	local current_win = vim.api.nvim_get_current_win()
	vim.cmd("vsplit")
	state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.win, ensure_buffer())
	vim.api.nvim_win_set_option(state.win, "wrap", false)

	-- Keep focus in the original window to respect the current layout
	vim.api.nvim_set_current_win(current_win)

	return state.win
end

function M.is_open()
	return is_valid_win(state.win)
end

local function build_tree_lines(items)
	state.locations = {}
	local lines = {}

	-- Header and a bit of breathing room
	table.insert(lines, "Complexity map")
	table.insert(lines, "")

	local function depth_for(index)
		local depth = 0
		local parent = items[index].parent
		while parent do
			depth = depth + 1
			parent = items[parent] and items[parent].parent
		end
		return depth
	end

	for idx, item in ipairs(items) do
		local depth = depth_for(idx)
		local indent = string.rep("  ", depth)
		local label = item.name or item.kind or "node"
		local score = string.format("%6.1f", item.complexity or 0)
		local text = string.format("%s- %-30s %s", indent, label, score)

		table.insert(lines, text)

		local line_index = #lines
		state.locations[line_index] = {
			bufnr      = item.bufnr,
			line       = item.line,
			complexity = item.complexity or 0,
		}
	end

	return lines
end

local function render_for_buffer(bufnr)
	if not is_valid_buf(bufnr) or bufnr == state.buf then
		return
	end

	local cfg = config()
	local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
	if not vim.tbl_contains(cfg.enabled_filetypes, filetype) then
		return
	end

	local treesitter = require("visual-complexity.treesitter")
	if not treesitter.ensure_parser(filetype) then
		return
	end

	local items = treesitter.collect_complexity(bufnr, filetype)
	local map_buf = ensure_buffer()
	local win = ensure_window()

	if #items == 0 then
		vim.api.nvim_buf_set_lines(map_buf, 0, -1, false, { "No complexity data available" })
		vim.api.nvim_buf_clear_namespace(map_buf, map_ns, 0, -1)
		return
	end

	local lines = build_tree_lines(items)
	vim.api.nvim_buf_set_lines(map_buf, 0, -1, false, lines)
	vim.api.nvim_buf_clear_namespace(map_buf, map_ns, 0, -1)

	for line_index, loc in pairs(state.locations) do
		local hl_group = util.get_highlight_group(loc.complexity or 0)
		vim.api.nvim_buf_add_highlight(map_buf, map_ns, hl_group, line_index - 1, 0, -1)
	end

	vim.api.nvim_win_set_buf(win, map_buf)
end

function M.open_for_current_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	render_for_buffer(bufnr)
end

function M.on_buf_enter()
	if not M.is_open() then
		return
	end

	local bufnr = state.pinned_bufnr
	if not is_valid_buf(bufnr) then
		bufnr = vim.api.nvim_get_current_buf()
	end

	render_for_buffer(bufnr)
end

function M.toggle_pin_for_current_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	if not is_valid_buf(bufnr) or bufnr == state.buf then
		return
	end

	if state.pinned_bufnr == bufnr then
		state.pinned_bufnr = nil
		vim.notify("[visual-complexity] Map unpinned", vim.log.levels.INFO)
	else
		state.pinned_bufnr = bufnr
		vim.notify("[visual-complexity] Map pinned to current buffer", vim.log.levels.INFO)
		render_for_buffer(bufnr)
	end
end

function M.jump_to_selection()
	if not is_valid_buf(state.buf) then
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1]
	local target = state.locations[row]
	if not target or not is_valid_buf(target.bufnr) then
		return
	end

	local target_win = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local win_buf = vim.api.nvim_win_get_buf(win)
		if win ~= state.win and win_buf == target.bufnr then
			target_win = win
			break
		end
	end

	if not target_win then
		vim.cmd("vsplit")
		target_win = vim.api.nvim_get_current_win()
	end

	vim.api.nvim_win_set_buf(target_win, target.bufnr)
	vim.api.nvim_set_current_win(target_win)
	vim.api.nvim_win_set_cursor(target_win, { target.line + 1, 0 })
end

function M.close()
	if is_valid_win(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
	state.win = nil
	state.buf = nil
	state.locations = {}
end

return M

