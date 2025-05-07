local M = {}

M.config = require("visual-complexity.config")
M.annotations = require("visual-complexity.annotations")

M.namespace_id = require("visual-complexity.shared").namespace_id

local function render_virtual_text_on_events()
	local config = require("visual-complexity.config").options
	if not config.show_bar then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local calculate = require("visual-complexity.complexity_calculations").calculate
	local complexity, func_count, cond_count, annotations = calculate(lines)

	for _, ann in ipairs(annotations) do
		require("visual-complexity.util").display_virtual_text(bufnr, ann.line, complexity, func_count, cond_count)
	end
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePost" }, {
	callback = render_virtual_text_on_events,
})

function M.setup(user_config)
	M.config.setup(user_config)
end

return M
