local M = {}

local config_module = require('visual-complexity.config')
M.config = config_module
config_module.setup()

local util = require('visual-complexity.util')
local ns_id = vim.api.nvim_create_namespace("nvim_visual_complexity")

local function calculate_visual_complexity(lines)
    local weights = M.config.options.weights
    local raw_lines = #lines
    local func_count, cond_count = 0, 0

    for _, line in ipairs(lines) do
        local f, c = util.analyze_line(line)
        func_count = func_count + f
        cond_count = cond_count + c
    end

    local complexity = raw_lines * weights.line + func_count * weights.func + cond_count * weights.conditional
    return complexity, func_count, cond_count
end

local function display_visual_complexity(bufnr, start_line, end_line)
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
    local complexity, func_count, cond_count = calculate_visual_complexity(lines)

    local hl_group = util.get_highlight_group(complexity)
    local text = string.format(M.config.options.virtual_text_format, complexity, func_count, cond_count)

    if M.config.options.show_bar then
        text = util.create_bar(complexity) .. "  " .. text
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_line, 0, {
        virt_text = {{text, hl_group}},
        virt_text_pos = "eol",
    })
end

local function ensure_treesitter_parser(filetype)
    local parsers = require("nvim-treesitter.parsers").get_parser_configs()
    if not parsers[filetype] then
        local ok = vim.fn.confirm(string.format("Install Tree-sitter parser for '%s'?", filetype), "&Yes\n&No") == 1
        if ok then
            vim.cmd("TSInstall " .. filetype)
        end
        return ok
    end
    return true
end

local lang_nodes = require('visual-complexity.lang_nodes')

local function traverse_tree(bufnr, node, lang, depth)
    depth = depth or 0
    local type = node:type()
    local start_row, _, end_row, _ = node:range()

    local complex_nodes = lang_nodes.language_node_map[lang] or {}
    if complex_nodes[type] then
        display_visual_complexity(bufnr, start_row, end_row)
    end

    for child in node:iter_children() do
        if child:named() then
            traverse_tree(bufnr, child, lang, depth + 1)
        end
    end
end

local function analyze_current_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[bufnr].filetype

    if not vim.tbl_contains(M.config.options.enabled_filetypes, filetype) then
        return
    end

    if not ensure_treesitter_parser(filetype) then
        vim.notify("[visual-complexity] Missing Tree-sitter parser for " .. filetype, vim.log.levels.WARN)
        return
    end

    local parser = vim.treesitter.get_parser(bufnr)
    if not parser then
        vim.notify("[visual-complexity] Could not get parser for buffer", vim.log.levels.ERROR)
        return
    end

    -- Clear previous virtual text
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    local tree = parser:parse()[1]
    if not tree then
        vim.notify("[visual-complexity] Could not parse tree", vim.log.levels.ERROR)
        return
    end

    traverse_tree(bufnr, tree:root(), filetype)
end

vim.api.nvim_create_autocmd({"BufEnter", "TextChanged", "InsertLeave"}, {
    pattern = "*",
    callback = analyze_current_buffer,
})

function M.setup(user_config)
    M.config.setup(user_config)
end

function M.statusline_complexity()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local complexity = calculate_visual_complexity(lines)
    return string.format("C: %.1f", complexity)
end

function M.show_file_complexity()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local complexity, f, c = calculate_visual_complexity(lines)
    print(string.format("File Complexity: %.2f  |  Functions: %d  |  Conditionals: %d", complexity, f, c))
end

vim.api.nvim_create_user_command("VisualComplexity", M.show_file_complexity, {})

return M
