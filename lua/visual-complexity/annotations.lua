local M = {}

local shared = require("visual-complexity.shared")
local commands = require("visual-complexity.commands")
local annotation_ns_id = shared.annotations_namespace_id or shared.namespace_id

function M.clear(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, annotation_ns_id, 0, -1)
end

function M.show(bufnr, annotations)
	if not commands.show_reasons then
		return
	end

	for _, ann in ipairs(annotations) do
		if ann.line >= 0 and ann.line < vim.api.nvim_buf_line_count(bufnr) then
			vim.api.nvim_buf_set_extmark(bufnr, annotation_ns_id, ann.line, 0, {
				virt_text = { { ann.reason, "Comment" } },
				virt_text_pos = "eol",
			})
		end
	end
end

return M
