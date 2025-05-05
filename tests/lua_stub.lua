-- Lua test stub
local function example_function()
    if true then
        print("Hello, World!")
    end
end

local example_table = {
    key = function()
        return "value"
    end
}

return example_function, example_table