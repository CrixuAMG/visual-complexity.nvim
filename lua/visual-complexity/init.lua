local M = {}

M.config = require("visual-complexity.config")
M.complexity_calculations = require("visual-complexity.complexity_calculations")

M.annotations = require("visual-complexity.annotations")

M.namespace_id = require("visual-complexity.shared").namespace_id

local function render_virtual_text_on_events()
	local config = require("visual-complexity.config").options

	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
	if not vim.tbl_contains(config.enabled_filetypes, filetype) then
		return
	end

	if not config.show_bar then
		return
	end

	-- Clear existing bars
	vim.api.nvim_buf_clear_namespace(bufnr, M.namespace_id, 0, -1)

	local treesitter = require("visual-complexity.treesitter")

	-- Prefer per-context complexity when a Tree-sitter parser is available
	if treesitter.ensure_parser(filetype) then
		M.annotations.clear(bufnr)

		local parser = vim.treesitter.get_parser(bufnr, filetype)
		local tree = parser:parse()[1]
		local root = tree:root()

		treesitter.traverse_tree(bufnr, root, filetype)
		return
	end

	-- Fallback: file-level heuristic when Tree-sitter is unavailable
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local calculate = require("visual-complexity.complexity_calculations").calculate
	local complexity, func_count, cond_count, ann = calculate(lines)

	for _, a in ipairs(ann) do
		require("visual-complexity.util").display_virtual_text(bufnr, a.line, complexity, func_count, cond_count)
	end
end

local function setup_autocmds()
	local group = vim.api.nvim_create_augroup("VisualComplexity", { clear = true })

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePost" }, {
		group    = group,
		callback = render_virtual_text_on_events,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function()
			local ok, map = pcall(require, "visual-complexity.map")
			if not ok then
				return
			end
			map.on_buf_enter()
		end,
	})
end

local function setup_keymaps()
	local options = require("visual-complexity.config").options
	local keymaps = options.keymaps or {}

	if keymaps.toggle_reasons then
		vim.keymap.set("n", keymaps.toggle_reasons, "<cmd>ToggleComplexityReasons<CR>", {
			desc = "Toggle visual complexity reasons",
		})
	end

	if keymaps.open_map then
		vim.keymap.set("n", keymaps.open_map, "<cmd>VisualComplexityMap<CR>", {
			desc = "Open visual complexity map",
		})
	end

	if keymaps.toggle_map_pin then
		vim.keymap.set("n", keymaps.toggle_map_pin, "<cmd>VisualComplexityMapPin<CR>", {
			desc = "Pin visual complexity map to current buffer",
		})
	end
end

function M.setup(user_config)
	M.config.setup(user_config)
	setup_autocmds()
	setup_keymaps()
end

return M
