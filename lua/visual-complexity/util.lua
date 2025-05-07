local M = {}

function M.analyze_line(line)
	local func_patterns = {
		{ pattern = "%f[%a]function%f[%A]", reason = "Function declaration" },
		{ pattern = "%f[%a]local%s+function%f[%A]", reason = "Local function" },
	}

	local cond_patterns = {
		{ pattern = "%f[%a]if%f[%A]", reason = "If statement" },
		{ pattern = "%f[%a]else%f[%A]", reason = "Else clause" },
		{ pattern = "%f[%a]elseif%f[%A]", reason = "Elseif clause" },
		{ pattern = "%f[%a]while%f[%A]", reason = "While loop" },
		{ pattern = "%f[%a]for%f[%A]", reason = "For loop" },
		{ pattern = "%f[%a]try%f[%A]", reason = "Try block" },
		{ pattern = "%f[%a]catch%f[%A]", reason = "Catch block" },
	}

	local is_function = false
	local is_conditional = false
	local reasons = {}

	for _, entry in ipairs(func_patterns) do
		if line:match(entry.pattern) then
			is_function = true
			table.insert(reasons, entry.reason)
			break
		end
	end

	for _, entry in ipairs(cond_patterns) do
		if line:match(entry.pattern) then
			is_conditional = true
			table.insert(reasons, entry.reason)
			break
		end
	end

	return is_function and 1 or 0, is_conditional and 1 or 0, reasons
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

function M.display_virtual_text(bufnr, line, score, func_count, cond_count)
	local config = require("visual-complexity.config").options
	local virt_text = string.format(config.virtual_text_format, score, func_count, cond_count)
	local bar = M.create_bar(score)
	vim.api.nvim_buf_set_extmark(bufnr, require("visual-complexity.shared").namespace_id, line, 0, {
		virt_text = { { bar .. " " .. virt_text, config.highlight_group } },
		virt_text_pos = "eol",
	})
end

return M
