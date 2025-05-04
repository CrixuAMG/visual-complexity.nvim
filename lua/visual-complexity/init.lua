local M = {}
local M = {}

M.config = require("visual-complexity.config")
M.commands = require("visual-complexity.commands")
M.annotations = require("visual-complexity.annotations")
M.complexity_calculations = require("visual-complexity.complexity_calculations")
M.treesitter = require("visual-complexity.treesitter")

function M.setup(user_config)
	M.config.setup(user_config)
end

return M
