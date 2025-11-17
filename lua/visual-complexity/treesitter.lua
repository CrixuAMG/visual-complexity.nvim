local M = {}
local lang_nodes = require("visual-complexity.lang_nodes")
local annotations = require("visual-complexity.annotations")
local util = require("visual-complexity.util")

function M.ensure_parser(filetype)
	local parsers = require("nvim-treesitter.parsers")
	if not parsers.has_parser(filetype) then
		vim.notify("[visual-complexity] Missing Tree-sitter parser for " .. filetype, vim.log.levels.WARN)
		return false
	end
	return true
end

local function extract_name(lang, node_type, node, bufnr)
	local ok, get_node_text = pcall(function()
		return vim.treesitter.get_node_text
	end)
	if not ok or not get_node_text then
		return nil
	end

	local text = get_node_text(node, bufnr)
	if not text then
		return nil
	end

	if lang == "php" then
		if node_type == "class_declaration" then
			local name = text:match("class%s+([%w_]+)")
			if name then
				return name
			end
		elseif node_type == "method_declaration" or node_type == "function_definition" then
			local name = text:match("function%s+([%w_]+)")
			if name then
				return name
			end
		end
	elseif lang == "lua" then
		if node_type == "function" then
			local name = text:match("function%s+([%w%.:_]+)")
			if name then
				return name
			end
		end
	end

	return nil
end

function M.collect_complexity(bufnr, lang)
	local items = {}
	local lang_map = lang_nodes.language_node_map[lang]
	if not lang_map then
		return items
	end

	local parser = vim.treesitter.get_parser(bufnr, lang)
	if not parser then
		return items
	end

	local tree = parser:parse()[1]
	if not tree then
		return items
	end

	local root = tree:root()
	local calculate = require("visual-complexity.complexity_calculations").calculate

	local function visit(node, parent_index)
		local node_type = node:type()
		local start_row, _, end_row, _ = node:range()
		local current_index = parent_index

		if lang_map[node_type] then
			local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
			local complexity, func_count, cond_count = calculate(lines)

			table.insert(items, {
				kind       = node_type,
				name       = extract_name(lang, node_type, node, bufnr),
				bufnr      = bufnr,
				line       = start_row,
				complexity = complexity,
				func_count = func_count,
				cond_count = cond_count,
				parent     = parent_index,
			})
			current_index = #items
		end

		for child in node:iter_children() do
			if child:named() then
				visit(child, current_index)
			end
		end
	end

	visit(root, nil)
	return items
end


function M.traverse_tree(bufnr, node, lang)
	local type = node:type()
	local start_row, _, end_row, _ = node:range()

	local lang_map = lang_nodes.language_node_map[lang]
	if lang_map and lang_map[type] then
		local calculate = require("visual-complexity.complexity_calculations").calculate
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		local complexity, func_count, cond_count, ann = calculate(lines)

		-- Show a bar for this specific context (class/method) at its start line
		util.display_virtual_text(bufnr, start_row, complexity, func_count, cond_count)

		for _, a in ipairs(ann) do
			a.line = a.line + start_row
		end

		annotations.show(bufnr, ann)
	end

	for child in node:iter_children() do
		if child:named() then
			M.traverse_tree(bufnr, child, lang)
		end
	end
end

return M
