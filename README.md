# Visual Complexity

A small Neovim plugin that estimates structural complexity and shows it directly in your code using virtual text and a simple bar.

---

## Features

- Scores functions, classes, and methods based on lines, function definitions, and conditionals
- Weighted complexity formula with configurable weights
- Virtual text with color-based severity
- Optional bar graph for quick scanning
- Commands to show per-context and file-level complexity
- Optional statusline integration
- Optional complexity map window

---

## Installation

Using `lazy.nvim`:

```lua
{
  "crixuamg/visual-complexity.nvim",
  config = function()
    require("visual-complexity").setup()
  end,
}
```

---

## Configuration

```lua
require("visual-complexity").setup({
  enabled_filetypes = {
    "lua",
    "javascript",
    "typescript",
    "php",
  },
  -- By default, function count is hidden because it is usually 1 per method
  virtual_text_format = "Complexity: %.1f | Cond: %d",
  highlight_group     = "Comment",
  show_bar            = true,
  weights             = {
    line        = 1.0,
    func        = 2.0,
    conditional = 1.5,
    indent      = 0.1,
    clump       = 1.0,
  },
  severity_thresholds = {
    { max = 10,       group = "Comment" },
    { max = 25,       group = "WarningMsg" },
    { max = math.huge, group = "ErrorMsg" },
  },
  threshold_for_warnings = 15,

  keymaps = {
    -- Global mappings (you can set these to whatever fits your setup)
    toggle_reasons = nil,          -- Example: "<leader>vr"
    open_map       = nil,          -- Example: "<leader>vm"
    toggle_map_pin = nil,          -- Example: "<leader>vP"

    -- Local mappings inside the map window
    map = {
      jump       = "<CR>",
      close      = "q",
      toggle_pin = "p",
    },
  },
})
```

---

## Commands

- `:VisualComplexity`         – Recompute and show complexity for the current buffer using Tree-sitter.
- `:ToggleComplexityReasons`  – Toggle showing the reasons for the displayed complexity annotations.
- `:VisualComplexityMap`      – Open the complexity map window for the current buffer.
- `:VisualComplexityMapPin`   – Pin or unpin the map to the current buffer.

---

## Complexity map

The complexity map is a simple vertical window that lists the interesting nodes in the current buffer (for example classes and methods) with their complexity score.

- The map follows the current buffer by default.
- When pinned, it stays focused on the buffer it was pinned to.

Default keymaps inside the map buffer:

- `<CR>`  – Jump to the selected item in a code window
- `q`     – Close the map window
- `p`     – Toggle pin for the current buffer

---

## Statusline integration

Add this to your statusline (for example in a lualine section):

```lua
require("visual-complexity").statusline_complexity()
```

---

## Running tests

Tests for this plugin are written using [busted](https://olivinelabs.com/busted/) and the Neovim Lua runtime. From the project root, run:

```bash
busted tests
```

---

## Requirements

- Neovim 0.9+
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
