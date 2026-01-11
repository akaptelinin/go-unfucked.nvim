# go-unfucked.nvim 🍔

[![Tests](https://github.com/akaptelinin/go-unfucked.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/akaptelinin/go-unfucked.nvim/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Neovim BLAZINGLY FAST(didnt test) plugin that improves Go code readability with visual hints and highlighting.

## Features

| Feature | Description |
|---------|-------------|
| Import hints | Shows which symbols are used from each import |
| Receiver highlight | Highlights method receiver and its usages in distinct peach color (`#f5a97f`) |
| Error dim | Dims repetitive `if err != nil { return err }` blocks |
| Short names | Warns about short variable names, receiver names, and import aliases via [shortnames-linter](https://github.com/akaptelinin/shortnames-linter) |

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

**Error dim:**
```go
// This boilerplate gets dimmed so you can focus on actual logic:
if err != nil {
    return err
}
```

**Short names warning:**
```go
import (
    x "context"  // warning: import alias "x" is too short
)

func calc(x int) int {  // warning: "x" is too short
    return x * 2
}
```

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
        color = "#f5a97f",
        italic = false,
    },
    error_dim = {
        enabled = false,
        dim_simple_return = false,
        dim_wrapped_return = false,
        dim_percent = 40,
        dim_target = nil,
    },
    shortnames = {
        enabled = true,
    },
})
```

### Error dim options

| Option | Default | Description |
|--------|---------|-------------|
| `dim_percent` | `40` | How much to dim (0 = no dim, 100 = fully blended with target) |
| `dim_target` | `nil` | Target color to blend towards. If `nil`, uses nvim background color |

The dimming works by blending original syntax colors towards the target. With `dim_target = nil`, it automatically adapts to your colorscheme's background.

## Commands

| Command | Description |
|---------|-------------|
| `:GoImportHints` | Refresh import hints |
| `:GoImportHintsToggle` | Toggle import hints |
| `:GoErrorDimToggle` | Toggle error block dimming |
| `:GoErrorDimStatus` | Show error dim status |
| `:GoShortnamesRun` | Run shortnames linter |
| `:GoShortnamesToggle` | Toggle shortnames linter |

## Requirements

- Neovim >= 0.9.0
- Treesitter with Go parser (`TSInstall go`)

## Why restrict short names?

Why did you decide that single-letter names are correct approach? Is typing a paid feature on your keyboard? You think >2 letter variables are too long for Go, which is famously known for being as compact as possible?

Anyway, this plugin fixes goslop for you.

## Why only Neovim?

Why would anybody use other editors?

## Related

- [shortnames-linter](https://github.com/akaptelinin/shortnames-linter) — golangci-lint plugin for short name warnings
