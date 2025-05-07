local M = {}

M.show_reasons = false

function M.toggle_show_reasons()
	M.show_reasons = not M.show_reasons
	print("Visual complexity reasons: " .. (M.show_reasons and "ON" or "OFF"))
end

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
	annotations_module.show(bufnr, annotations)

	print(string.format("File Complexity: %.2f  |  Functions: %d  |  Conditionals: %d", complexity, f, c))
end

vim.api.nvim_create_user_command("VisualComplexity", function()
	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
	if not require("visual-complexity.treesitter").ensure_parser(filetype) then
		return
	end

	local parser = vim.treesitter.get_parser(bufnr, filetype)
	local tree = parser:parse()[1]
	local root = tree:root()

	require("visual-complexity.treesitter").traverse_tree(bufnr, root, filetype)
end, {})

return M
