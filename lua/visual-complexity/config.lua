local M = {}

local defaults = {
    enabled_filetypes = {
        "lua", "javascript", "typescript"
    },
    virtual_text_format = "Complexity: %.1f | Func: %d | Cond: %d",
    highlight_group = "Comment",
    show_bar = true,
    weights = {
        line = 1.0,
        func = 3.0,
        conditional = 2.0,
        indent = 0.1,
        clump = 1.0,
    },
    severity_thresholds = {
        { max = 10, group = "Comment" },
        { max = 25, group = "WarningMsg" },
        { max = math.huge, group = "ErrorMsg" },
    },
}

function M.setup(user_config)
    M.options = vim.tbl_deep_extend("force", {}, defaults, user_config or {})
end

setmetatable(M, {
    __index = function(_, key)
        return defaults[key]
    end
})

return M
