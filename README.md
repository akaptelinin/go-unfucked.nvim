# go-unfucked.nvim

[![Tests](https://github.com/akaptelinin/go-unfucked.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/akaptelinin/go-unfucked.nvim/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Neovim BLAZINGLY FAST(didnt test) plugin that improves Go code readability with visual hints and highlighting.

## Features

| Feature | Description |
|---------|-------------|
| Import hints | Shows which symbols are used from each import |
| Receiver highlight | Highlights method receiver in unique color |
| Error dim | Dims repetitive `if err != nil { return err }` blocks |

## Screenshots

**Import hints:**
```go
import (
    "fmt"      → Println, Printf, Sprintf
    "strings"  → Split, Join, Contains
    "os"       → unused
)
```

**Receiver highlighting:**
```go
func (handler *Handler) Process() {  // "handler" highlighted
    handler.db.Query()               // "handler" highlighted
}
```

## Why?

Why did you decide that single-letter names are correct? Is typing a paid feature on your keyboard? You think >2 letter variables are too long for Go, which is famously known for being as compact as possible?

Anyway, this plugin fixes goslop for you.

## Installation

### lazy.nvim

```lua
{
    "akaptelinin/go-unfucked.nvim",
    ft = "go",
    opts = {},
}
```

### packer.nvim

```lua
use {
    "akaptelinin/go-unfucked.nvim",
    ft = "go",
    config = function()
        require("go-unfucked").setup()
    end
}
```

## Configuration

```lua
require("go-unfucked").setup({
    import_hints = {
        enabled = true,
    },
    receiver_highlight = {
        color = "#ff9900",
    },
    error_dim = {
        enabled = false,
        dim_simple_return = false,
        dim_wrapped_return = false,
        dim_color = "#666666",
    },
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:GoImportHints` | Refresh import hints |
| `:GoImportHintsToggle` | Toggle import hints |
| `:GoErrorDimToggle` | Toggle error block dimming |
| `:GoErrorDimStatus` | Show error dim status |

## Requirements

- Neovim >= 0.9.0
- Treesitter with Go parser (`TSInstall go`)

## Why only Neovim?

Why would anybody use other editors?

## Related

- [shortnames-linter](https://github.com/akaptelinin/shortnames-linter) — golangci-lint plugin for short name warnings
