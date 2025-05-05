local util = require("visual-complexity.util")

local M = {}

function M.calculate(lines)
	local config = require("visual-complexity.config").options
	local weights = config.weights
	local raw_lines = #lines
	local func_count, cond_count = 0, 0

	local annotations = {}

	for i, line in ipairs(lines) do
		local f, c, reasons = util.analyze_line(line)
		func_count = func_count + f
		cond_count = cond_count + c

		if f > 0 then
			table.insert(annotations, { line = i - 1, reason = "Function detected - +" .. weights.func .. " score" })
		end
		if c > 0 then
			table.insert(
				annotations,
				{ line = i - 1, reason = "Conditional detected - +" .. weights.conditional .. " score" }
			)
		end

		-- Handle JavaScript object methods
		if line:match("%w+%s*:%s*function") or line:match("%w+%s*:%s*%(%s*%w*%s*%)%s*=>") then
			table.insert(annotations, { line = i - 1, reason = "JS Object Method detected - +" .. weights.func .. " score" })
		end
	end

	local complexity = raw_lines * weights.line + func_count * weights.func + cond_count * weights.conditional
	return complexity, func_count, cond_count, annotations
end

return M
