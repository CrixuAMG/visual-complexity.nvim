local M = {}

M.language_node_map = {
	lua = { ["function"] = true },
	python = { function_definition = true, class_definition = true },
	javascript = {
		function_declaration = true,
		method_definition = true,
		class_declaration = true,
		object_method = true,
		method_definition = true,
		arrow_function = true,
	},
	typescript = {
		function_declaration = true,
		method_definition = true,
		class_declaration = true,
		object_method = true,
		method_definition = true,
		arrow_function = true,
	},
	php = { method_declaration = true, function_definition = true, class_declaration = true },
	go = { function_declaration = true, method_declaration = true },
	rust = { function_item = true, impl_item = true },
	c = { function_definition = true },
	cpp = { function_definition = true },
}

return M
