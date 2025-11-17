local M = {}

local defaults = {
	enabled_filetypes = {
		"lua",
		"javascript",
		"typescript",
	},
	-- Default: focus on overall complexity and conditionals; function count is usually 1 per method
	virtual_text_format = "Complexity: %.1f | Cond: %d",
	highlight_group = "Comment",
	show_bar = true,
	weights = {
		line        = 1.0,
		func        = 3.0,
		conditional = 2.0,
		indent      = 0.1,
		clump       = 1.0,
	},
	severity_thresholds = {
		{ max = 10,      group = "Comment" },
		{ max = 25,      group = "WarningMsg" },
		{ max = math.huge, group = "ErrorMsg" },
	},
	threshold_for_warnings = 15, -- New threshold for showing warnings above lines
	keymaps = {
		toggle_reasons  = nil,
		open_map        = nil,
		toggle_map_pin  = nil,
		map             = {
			jump       = "<CR>",
			close      = "q",
			toggle_pin = "p",
		},
	},
}

local function deep_extend(target, source)
	for k, v in pairs(source) do
		if type(v) == "table" and type(target[k]) == "table" then
			target[k] = deep_extend(target[k], v)
		else
			target[k] = v
		end
	end
	return target
end

function M.setup(user_config)
	M.options = deep_extend(deep_extend({}, defaults), user_config or {})
end

setmetatable(M, {
	__index = function(_, key)
		return defaults[key]
	end,
})

return M
