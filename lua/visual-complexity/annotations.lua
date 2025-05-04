local M = {}
local annotation_ns_id = vim.api.nvim_create_namespace("nvim_visual_complexity_annotations")

function M.show(bufnr, annotations)
	vim.api.nvim_buf_clear_namespace(bufnr, annotation_ns_id, 0, -1)
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
