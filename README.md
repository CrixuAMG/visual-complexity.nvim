# Visual Complexity

`visual-complexity` is a Neovim plugin that displays the visual complexity of code structures such as classes, functions, and methods as virtual text. It uses Tree-sitter for accurate parsing and provides configurable options to customize the plugin's behavior.

## Features

- Displays visual complexity above class definitions, methods, functions, and closures.
- Uses Tree-sitter for accurate parsing.
- Configurable virtual text format, highlight group, complexity thresholds, and enabled file types.

## Requirements

- Neovim 0.10+
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add the following to your `lazy.nvim` configuration:

```lua
{
    'crixuamg/visual-complexity.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
        require('visual-complexity').setup()
    end,
}
```

## Configuration

```lua
require('visual-complexity').setup({
    virtual_text_format = "Complexity: %d, Functions: %d, Conditionals: %d", -- Format of the virtual text
    highlight_group = "Comment", -- Highlight group for the virtual text
    complexity_thresholds = {
        low = 10,
        medium = 20,
        high = 30,
    }, -- Complexity thresholds
    enabled_filetypes = {"lua", "python", "javascript", "typescript"}, -- File types to enable the plugin for
})
```

### Options
- virtual_text_format: A string format for the virtual text. Default is "Complexity: %d, Functions: %d, Conditionals: %d".
- highlight_group: The highlight group to use for the virtual text. Default is "Comment".
- complexity_thresholds: A table defining complexity thresholds. Default is { low = 10, medium = 20, high = 30 }.
- enabled_filetypes: A list of file types to enable the plugin for. Default is {"lua", "python", "javascript", "typescript"}.

## Usage
Once installed and configured, the plugin will automatically display the visual complexity above class definitions, methods, functions, and closures as virtual text. The complexity is calculated based on the number of lines, functions, and conditional statements within each structure.

