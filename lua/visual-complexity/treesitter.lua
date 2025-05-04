local M = {}
local lang_nodes = require("visual-complexity.lang_nodes")
local annotations = require("visual-complexity.annotations")

function M.ensure_parser(filetype)
	local parsers = require("nvim-treesitter.parsers")
	if not parsers.has_parser(filetype) then
		vim.notify("[visual-complexity] Missing Tree-sitter parser for " .. filetype, vim.log.levels.WARN)
		return false
	end
	return true
end

function M.traverse_tree(bufnr, node, lang)
	local type = node:type()
	local start_row, _, end_row, _ = node:range()
	if lang_nodes.language_node_map[lang][type] then
		local calc = require("visual-complexity.complexity_calculations").calculate
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		local complexity, _, _, ann = calc(lines)
		annotations.show(bufnr, ann)
	end
	for child in node:iter_children() do
		if child:named() then
			M.traverse_tree(bufnr, child, lang)
		end
	end
end

return M
