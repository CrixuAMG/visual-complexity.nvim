local M = {}

local config_module = require('visual-complexity.config')
M.config = config_module
config_module.setup()

local util = require('visual-complexity.util')
local ns_id = vim.api.nvim_create_namespace("nvim_visual_complexity")

-- Load commands module
local commands = require('visual-complexity.commands')

-- Default show_reasons flag
commands.show_reasons = false

local function calculate_visual_complexity(lines)
    local weights = M.config.options.weights
    local raw_lines = #lines
    local func_count, cond_count = 0, 0
    local indent_score, clump_penalty = 0, 0
    local non_empty_streak = 0

    local annotations = {}

    for i, line in ipairs(lines) do
        local f, c, reasons = util.analyze_line(line)
        func_count = func_count + f
        cond_count = cond_count + c

        -- Add annotations if functions or conditionals are detected
        if f > 0 then
            table.insert(annotations, { line = i - 1, reason = "Function detected" })
        end
        if c > 0 then
            table.insert(annotations, { line = i - 1, reason = "Conditional detected" })
        end

        -- Check for indentation issues
        local indent = line:match("^(%s*)")
        local indent_len = indent and #indent or 0
        indent_score = indent_score + indent_len

        if indent_len >= 8 then
            table.insert(annotations, {
                line = i - 1,
                reason = string.format("Deep indentation (%d spaces)", indent_len),
            })
        end

        -- Check for clumping issues (too many lines without spacing)
        if line:match("^%s*$") then
            non_empty_streak = 0
        else
            non_empty_streak = non_empty_streak + 1
            if non_empty_streak > 10 then
                clump_penalty = clump_penalty + 1
                table.insert(annotations, {
                    line = i - 1,
                    reason = "Clumping detected: too many lines without spacing",
                })
            end
        end
    end

    local complexity =
        raw_lines * weights.line +
        func_count * weights.func +
        cond_count * weights.conditional +
        indent_score * (weights.indent or 0.1) +
        clump_penalty * (weights.clump or 1.0)

    return complexity, func_count, cond_count, annotations
end

local function show_complexity_annotations(bufnr, annotations)
    local diagnostics = {}
    -- Only add diagnostics if show_reasons is enabled
    if commands.show_reasons then
        for _, ann in ipairs(annotations) do
            table.insert(diagnostics, {
                lnum = ann.line,
                col = 0,
                severity = vim.diagnostic.severity.INFO,
                source = "visual-complexity",
                message = ann.reason,
            })
        end
    end
    -- Set the diagnostics
    vim.diagnostic.set(ns_id, bufnr, diagnostics, {})
end

local function display_visual_complexity(bufnr, start_line, end_line)
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
    local complexity, func_count, cond_count, annotations = calculate_visual_complexity(lines)

    local hl_group = util.get_highlight_group(complexity)
    local text = string.format(M.config.options.virtual_text_format, complexity, func_count, cond_count)

    if M.config.options.show_bar then
        text = util.create_bar(complexity) .. "  " .. text
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_line, 0, {
        virt_text = {{text, hl_group}},
        virt_text_pos = "eol",
    })

    -- Show annotations if reasons are enabled
    show_complexity_annotations(bufnr, annotations)
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
