# tfm.nvim

Neovim plugin for Terminal File Manager integration (specifically [yazi]).

> **Note:** This is a personal fork of [Rolv-Apneseth/tfm.nvim], stripped down to work only with my setup (Yazi, latest Neovim, opinionated defaults, lazy-loading).

## Requirements

- Neovim v0.11+
- [yazi]

## Configuration

Configuration is done via `vim.g.tfm`:

### Minimal

```lua
vim.pack.add({ "https://github.com/pencelheimer/tfm.nvim" })

vim.keymap.set("n", "\\", "<cmd>Tfm<CR>", { desc = "TFM" })
```

### Full

```lua
vim.pack.add({ "https://github.com/pencelheimer/tfm.nvim" })

-- Settings
vim.g.tfm = {
    -- Customise UI (defaults shown below)
    ui = {
        height = 0.9,
        width = 0.9,
        x = 0.5,
        y = 0.5,
    },

    -- Custom keybindings applied within the TFM terminal buffer
    keybindings = {
        ["<ESC>"] = "q",
        ["<C-v>"] = "<C-\\><C-O>:lua require('tfm').set_next_open_mode(require('tfm').OPEN_MODE.vsplit)<CR><CR>",
        ["<C-x>"] = "<C-\\><C-O>:lua require('tfm').set_next_open_mode(require('tfm').OPEN_MODE.split)<CR><CR>",
        ["<C-t>"] = "<C-\\><C-O>:lua require('tfm').set_next_open_mode(require('tfm').OPEN_MODE.tabedit)<CR><CR>",
    },
}

-- Keybindings
vim.keymap.set("n", "<leader>e", "<cmd>Tfm<CR>", { desc = "TFM" })
vim.keymap.set("n", "<leader>mh", "<cmd>TfmSplit<CR>", { desc = "TFM - horizontal split" })
vim.keymap.set("n", "<leader>mv", "<cmd>TfmVsplit<CR>", { desc = "TFM - vertical split" })
vim.keymap.set("n", "<leader>mt", "<cmd>TfmTabedit<CR>", { desc = "TFM - new tab" })
```

## Commands

These commands are registered automatically on startup and lazy-load the plugin on invocation:

| Command | Action |
| --- | --- |
| `:Tfm [path]` | Open Yazi in current window |
| `:TfmSplit [path]` | Open selected file(s) in horizontal split |
| `:TfmVsplit [path]` | Open selected file(s) in vertical split |
| `:TfmTabedit [path]` | Open selected file(s) in new tab |

### Configuration - UI

| Key | Type | Default | Value |
| --- | ---- | ------- | ----- |
| `height` | `number` | `0.9` | From 0 to 1 (0 = 0% of screen and 1 = 100% of screen). |
| `width` | `number` | `0.9` | From 0 to 1 (0 = 0% of screen and 1 = 100% of screen). |
| `x` | `number` | `0.5` | From 0 to 1 (0 = left most of screen and 1 = right most of screen). |
| `y` | `number` | `0.5` | From 0 to 1 (0 = top most of screen and 1 = bottom most of screen). |

## Lua API

### `open()`

Opens the TFM, focusing the file from the current buffer, and falling back to the `CWD` if that is not possible.

### `open(path_to_open, open_mode)`

Opens the TFM at the given destination. If the path is a file, focuses that file. Selected file(s) will be
opened with the given mode.

- Setting `path_to_open` to `nil` is equivalent to calling `open()`
- `open_mode` should be an option from the enum defined below. Defaults to opening file(s) in the current window if an invalid option is received

### `set_next_open_mode(open_mode)`

Changes the next mode with which to open/edit selected files. Can be run while the terminal window is open.

- `open_mode` should be an option from the enum defined below.

### `enum OPEN_MODE`

Enum to configure modes with which to open/edit selected files.

| Variant | Action |
| ------- | ------ |
| `vsplit` | Open files in vertical split |
| `split` | Open files in horizontal split |
| `tabedit` | Open files in tab |

## Credit

- [@Rolv-Apneseth](https://github.com/Rolv-Apneseth) for the original [Rolv-Apneseth/tfm.nvim]
- [@kelly-lin](https://github.com/kelly-lin) for writing [ranger.nvim](https://github.com/kelly-lin/ranger.nvim)

[yazi]: https://github.com/sxyazi/yazi
[Rolv-Apneseth/tfm.nvim]: https://github.com/Rolv-Apneseth/tfm.nvim
