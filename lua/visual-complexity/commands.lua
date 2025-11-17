local M = {}

M.show_reasons = false

function M.toggle_show_reasons()
	M.show_reasons = not M.show_reasons
	print("Visual complexity reasons: " .. (M.show_reasons and "ON" or "OFF"))

	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local annotations = require("visual-complexity.annotations")

	if not M.show_reasons then
		annotations.clear(bufnr)
		return
	end

	-- Re-run VisualComplexity for the current buffer so reasons are updated immediately
	pcall(vim.cmd, "VisualComplexity")
end


vim.api.nvim_create_user_command("VisualComplexityMap", function()
	local ok, map = pcall(require, "visual-complexity.map")
	if not ok then
		vim.notify("[visual-complexity] Map module not available", vim.log.levels.ERROR)
		return
	end
	map.open_for_current_buffer()
end, {})

vim.api.nvim_create_user_command("VisualComplexityMapPin", function()
	local ok, map = pcall(require, "visual-complexity.map")
	if not ok then
		vim.notify("[visual-complexity] Map module not available", vim.log.levels.ERROR)
		return
	end
	map.toggle_pin_for_current_buffer()
end, {})

vim.api.nvim_create_user_command("ToggleComplexityReasons", M.toggle_show_reasons, {})

function M.show_file_complexity(calculate_visual_complexity)
	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local complexity, f, c, annotations = calculate_visual_complexity(lines)

	-- Display annotations
	local annotations_module = require("visual-complexity.annotations")
	annotations_module.clear(bufnr)
	annotations_module.show(bufnr, annotations)

	print(string.format("File Complexity: %.2f  |  Functions: %d  |  Conditionals: %d", complexity, f, c))
end

vim.api.nvim_create_user_command("VisualComplexity", function()
	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

	local shared = require("visual-complexity.shared")
	local annotations = require("visual-complexity.annotations")

	-- Clear existing bars and annotations so repeated calls do not duplicate output
	vim.api.nvim_buf_clear_namespace(bufnr, shared.namespace_id, 0, -1)
	annotations.clear(bufnr)

	if not require("visual-complexity.treesitter").ensure_parser(filetype) then
		return
	end

	local parser = vim.treesitter.get_parser(bufnr, filetype)
	local tree = parser:parse()[1]
	local root = tree:root()

	require("visual-complexity.treesitter").traverse_tree(bufnr, root, filetype)
end, {})

return M
