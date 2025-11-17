local M = {}

M.namespace_id = vim.api.nvim_create_namespace("visual_complexity")
M.annotations_namespace_id = vim.api.nvim_create_namespace("visual_complexity_annotations")

return M