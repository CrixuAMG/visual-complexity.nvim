package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

_G.vim = {
    api = {
        nvim_get_current_buf = function() return 1 end,
        nvim_buf_is_valid = function(_) return true end,
        nvim_buf_get_lines = function(_, _, _, _) return {} end,
        nvim_buf_clear_namespace = function(_, _, _, _) end,
        nvim_buf_set_extmark = function(_, _, _, _, _) end,
        nvim_create_namespace = function(_) return 1 end,
        nvim_notify = function(_, _, _) end,
        nvim_create_user_command = function(_, _, _) end,
    },
    fn = {
        readfile = function(path)
            local file = io.open(path, "r")
            if not file then return {} end
            local content = file:read("*a")
            file:close()
            return vim.split(content, "\n")
        end,
    },
    split = function(input, sep)
        local t = {}
        for str in string.gmatch(input, "([^" .. sep .. "]+)") do
            table.insert(t, str)
        end
        return t
    end,
    notify = function(msg, level)
        print("[Mock Notify]", msg, level)
    end,
}

local busted = require("busted")
local visual_complexity = require("visual-complexity")

require("visual-complexity.config").setup({})

busted.describe("Visual Complexity Plugin", function()
    busted.it("should calculate complexity for Lua stub", function()
        local lua_stub = vim.fn.readfile("tests/lua_stub.lua")
        local complexity, _, _, annotations = visual_complexity.complexity_calculations.calculate(lua_stub)
        assert.is_true(complexity > 0)
        assert.is_not_nil(annotations)
    end)

    busted.it("should calculate complexity for JavaScript stub", function()
        local js_stub = vim.fn.readfile("tests/js_stub.js")
        local complexity, func_count, cond_count, annotations = visual_complexity.complexity_calculations.calculate(js_stub)
        assert.is_true(complexity > 0)
        assert.are.equal(2, func_count)
        assert.are.equal(1, cond_count)
        assert.is_not_nil(annotations)
    end)

    busted.it("should calculate complexity for PHP stub", function()
        local php_stub = vim.fn.readfile("tests/php_stub.php")
        local complexity, func_count, cond_count, annotations = visual_complexity.complexity_calculations.calculate(php_stub)
        assert.is_true(complexity > 0)
        assert.are.equal(2, func_count)
        assert.are.equal(1, cond_count)
        assert.is_not_nil(annotations)
    end)
end)