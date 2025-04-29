local M = {}

function M.analyze_line(line)
    local func_patterns = {
        "%f[%a]function%f[%A]",
        "%f[%a]local%s+function%f[%A]"
    }

    local cond_patterns = {
        "%f[%a]if%f[%A]",
        "%f[%a]else%f[%A]",
        "%f[%a]while%f[%A]",
        "%f[%a]for%f[%A]",
        "%f[%a]try%f[%A]",
        "%f[%a]catch%f[%A]"
    }

    local is_function = false
    local is_conditional = false

    for _, pat in ipairs(func_patterns) do
        if line:match(pat) then
            is_function = true
            break
        end
    end

    for _, pat in ipairs(cond_patterns) do
        if line:match(pat) then
            is_conditional = true
            break
        end
    end

    return is_function and 1 or 0, is_conditional and 1 or 0
end

function M.get_highlight_group(score)
    for _, threshold in ipairs(require("visual-complexity.config").options.severity_thresholds) do
        if score <= threshold.max then
            return threshold.group
        end
    end
    return require("visual-complexity.config").options.highlight_group
end

function M.create_bar(score)
    local max_blocks = 10
    local filled = math.min(max_blocks, math.floor(score / 2))
    return string.rep("█", filled) .. string.rep("░", max_blocks - filled)
end

return M
