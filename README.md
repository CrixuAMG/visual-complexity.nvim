# Visual Complexity

## ✨ Features

- Scores functions, classes, and methods based on lines, function definitions, and conditionals
- Weighted complexity formula with customizable values
- Virtual text with color-coded severity indicators
- Optional bar graph for quick visual feedback
- Command to show total file complexity
- Optional statusline integration

---

## 📦 Installation

Using `lazy.nvim`:

```lua
{
  'crixuamg/visual-complexity.nvim',
  config = function()
    require('visual-complexity').setup()
  end
}
```

---

## ⚙️ Configuration

```lua
require('visual-complexity').setup({
    enabled_filetypes = {
        "lua", "javascript", "typescript"
    },
    virtual_text_format = "Complexity: %.1f | Func: %d | Cond: %d",
    highlight_group = "Comment",
    show_bar = true,
    weights = {
        line = 1.0,
        func = 2.0,
        conditional = 1.5,
        indent = 0.1,
        clump = 1.0,
    },
    severity_thresholds = {
        { max = 10, group = "Comment" },
        { max = 25, group = "WarningMsg" },
        { max = math.huge, group = "ErrorMsg" },
    },
    threshold_for_warnings = 15, -- Threshold for showing warnings above lines
})
```

---

## 📈 Commands

- `:VisualComplexity` — Print total file complexity in the command area.
- `:ToggleComplexityReasons` — Toggle showing the reasons for the displayed complexity.

---

## 📊 Statusline Integration

Add this to your statusline (e.g. lualine section):

```lua
require('visual-complexity').statusline_complexity()
```

---

## 🧪 Running Tests

To run the tests for this plugin, ensure you have `busted` installed. You can install it using `luarocks`:

```bash
luarocks install busted
```

Then, navigate to the plugin's root directory and run:

```bash
busted tests
```

This will execute all the test cases located in the `tests/` directory.

---

## 🔌 Requirements

- Neovim 0.9+
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
