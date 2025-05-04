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
	local complexity, f, c = calculate_visual_complexity(lines)
	print(string.format("File Complexity: %.2f  |  Functions: %d  |  Conditionals: %d", complexity, f, c))
end

vim.api.nvim_create_user_command("VisualComplexity", function()
	M.show_file_complexity(require("visual-complexity.complexity_calculations").calculate)
end, {})

return M
