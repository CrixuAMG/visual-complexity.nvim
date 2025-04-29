local M = {}

M.config = require('visual-complexity.config')

-- Function to calculate visual complexity
local function calculate_visual_complexity(lines)
    local complexity = 0
    local function_count = 0
    local conditional_count = 0

    for _, line in ipairs(lines) do
        complexity = complexity + 1
        if line:match("%f[%a]function%f[%A]") or line:match("%f[%a]local%s+function%f[%A]") then
            function_count = function_count + 1
        end
        if line:match("%f[%a]if%f[%A]") or line:match("%f[%a]else%f[%A]") or line:match("%f[%a]while%f[%A]") or line:match("%f[%a]for%f[%A]") or line:match("%f[%a]try%f[%A]") or line:match("%f[%a]catch%f[%A]") then
            conditional_count = conditional_count + 1
        end
    end

    return complexity, function_count, conditional_count
end

-- Function to display visual complexity as virtual text
local function display_visual_complexity(bufnr, start_line, end_line)
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
    local complexity, function_count, conditional_count = calculate_visual_complexity(lines)

    local complexity_text = string.format(M.config.virtual_text_format, complexity, function_count, conditional_count)
    local ns_id = vim.api.nvim_create_namespace("nvim_visual_complexity")
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_line, 0, {
        virt_text = {{complexity_text, M.config.highlight_group}},
        virt_text_pos = "eol",
    })
end

-- Function to check if Tree-sitter parser is installed
local function check_treesitter_parser(filetype)
    local parsers = require("nvim-treesitter.parsers").get_parser_configs()
    if not parsers[filetype] then
        local choice = vim.fn.confirm(
            string.format("Tree-sitter parser for %s is not installed. Install it?", filetype),
            "&Yes\n&No"
        )
        if choice == 1 then
            vim.cmd("TSInstall " .. filetype)
        else
            return false
        end
    end
    return true
end

-- Function to parse the buffer using Tree-sitter
local function parse_buffer_with_treesitter()
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[bufnr].filetype
    if not vim.tbl_contains(M.config.enabled_filetypes, filetype) then
        return
    end

    if not check_treesitter_parser(filetype) then
        return
    end

    local parser = vim.treesitter.get_parser(bufnr)
    local tree = parser:parse()[1]
    local root = tree:root()

    local function traverse(node)
        local node_type = node:type()
        local start_row, _, end_row, _ = node:range()

        if node_type == 'class' or node_type == 'function' or node_type == 'method' then
            display_visual_complexity(bufnr, start_row, end_row)
        end

        -- Recursively traverse child nodes
        if node:named_child_count() > 0 then
            for child in node:iter_children() do
                traverse(child)
            end
        end
    end

    traverse(root)
end

-- Autocommand to update visual complexity on buffer enter and text change
vim.api.nvim_create_autocmd({"BufEnter", "TextChanged", "InsertLeave"}, {
    pattern = "*",
    callback = parse_buffer_with_treesitter,
})

-- Function to set up the plugin with user configuration
function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

return M
