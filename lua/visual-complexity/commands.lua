local M = {}

-- Default show_reasons flag
M.show_reasons = false

-- Toggle the show_reasons flag
function M.toggle_show_reasons()
    M.show_reasons = not M.show_reasons
    if M.show_reasons then
        print("Visual complexity reasons: ON")
    else
        print("Visual complexity reasons: OFF")
    end
end

vim.api.nvim_create_user_command("ToggleComplexityReasons", M.toggle_show_reasons, {})

return M
