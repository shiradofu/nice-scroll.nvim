<p align="center">
  <h1 align="center">👍 nice-scroll.nvim</h1>
</p>

<p align="center">
  Happiness begins with a comfortable scroll.
</p>

https://user-images.githubusercontent.com/43514606/184519525-0cbe7619-b4cf-4c9e-89fe-dd99884b7a92.mov

This is an alpha stage plugin, so it still may not be so 'nice'. Public API
might be changed.

## ✊ Motivation

Neovim has really strong search and jump features, but they're too strong for me
to follow the cursor. It's hopping and skipping around the editor like an
innocent child. That's fine for a child, but not so for a cursor.

This plugin can hook into cursor jumps and scroll the page to bring it where it
is easy to see. This could be applied to traversing search results by `n`/`N` ,
jumps with like `<C-o>`,`g;` or lua functions such as
`vim.diagnostic.goto_next`, and even the `<CR>` in the search from the cmdline!

## 👋 installation

neovim 0.7+ required.

with packer.nvim:

```lua
use {
  'shiradofu/nice-scroll.nvim',
  config = function()
    require('nice-scroll').setup {}
  end,
}
```

## ✌️ Usage

Note: The configs below are just examples. This plugin does not provide default
key mappings.

### Base Functions

#### `require('nice-scroll').adjust()`

`adjust()` brings the current line to the 'nice' position (default is the
quarter of the window from the top of it).

#### `require('nice-scroll').adjust_eof()`

If you execute `adjust()` near the EOF, it raises too much and the visible range
of the file would be quite small. To prevent this, `adjust_eof()` pays attention
to the EOF and adjusts the scroll. By default, it keeps the EOF out of the 3/4
range of the window.

#### keymap examples

You can set keymaps like this and manually adjust the scroll position. These are
kind a collegues of `zz`, `zt`, or `zb`.

```lua
vim.keymap.set({'n', 'x' }, 'zh', "<Plug>(nice-scroll-adjust)")

-- Reverse version: See `hook()`'s second argument description for details.
vim.keymap.set({'n', 'x' }, 'zl', "<Plug>(nice-scroll-adjust-r)")

-- EOF attentive version
vim.keymap.set({'n', 'x' }, 'zh', "<Plug>(nice-scroll-adjust-eof)")

-- Specifying poistion
-- This will bring the cursorline to 10 line below the top of the window
vim.keymap.set({'n', 'x' }, 'zh', function() require('nice-scroll').adjust(10) end)
```

#### Vim commands

Vim commands `NiceScrollAdjust` and `NiceScrollAdjust` are also available.

### Hooking into Jumps

#### `require('nice-scroll').hook()`

`hook()` function allows you to hook into a cursor jump and execute
`adjust_eof()`. `hook()` takes 2 araguments: `hooked` and `opts`. If the type of
`hooked` is string, it will passed to `vim.cmd('execute "normal! %s"')` after
properly escaped. If it is function, it will run directly.

`opts` is a table whose keys and default values are the followings:

```lua
{
  -- If true, mappings using v:count1 like 3g; can be used.
  -- This has effect only when `hooked` is a string.
  -- For most simple rhs, `hook()` automatically add v:count1, but you can
  -- also include '%d' in `hooked` and specify where to put it.
  countable = false,
  -- If true, the position where the cursorline will be moved is inverted.
  -- Suppose you configure the plugin to move the cursorline 10 lines below
  -- from the top of the window. With this option, the cursorline will be moved
  -- to 10 lines above from the bottom of the window.
  -- This is useful when scrolling up continuously like `N`.
  reverse = false,

  -- Available only when `hooked` is a string.
  -- print a string that is passed to vim.cmd.
  debug = false,
}
```

Note: `adjust_eof()` will be executed **only when the jump had the page
scrolled**.

#### keymap examples

```lua
vim.keymap.set({ 'n', 'x' }, 'g;', function()
  require('nice-scroll').hook('g;', { countable = true })
end)
vim.keymap.set({ 'n', 'x' }, '[q', function()
  require('nice-scroll').hook('<Cmd>cprev<CR>', { countable = true, reverse = true })
end)
vim.keymap.set({ 'n', 'x' }, ']e', function()
  require('nice-scroll').hook(vim.diagnostic.goto_next)
end)
```

##### 'nice' defaults for `n` and `N`

Hooking into `n` and `N` are quite usual use cases, so the following defaults
are set to the options.

```lua
-- for `n`
{ countable = true, reverse = false }

-- for `N`
{ countable = true, reverse = true }
```

### Scroll on Search

If the `search1` property of the configuration table is set, and the cursorline
is in the specified range, `adjust_eof()` will be executed on submitting a
search.

## 💪 Configuration

The values below are default.

```lua
-- All options accept positive numbers.
-- n >= 1: n is considered as a fixed number of lines.
-- n < 1: n is considered as the ratio against the current window height.
require('nice-scroll').setup {

  -- Distance from the top end of the window:
  -- `adjust()` will move the cursorline to this position.
  default = 0.25,

  -- Distance from the top end of the window:
  -- `adjust_eof()` keep the EOF out of this range.
  -- If nil is set, `adjust_eof()` always executes `adjust()`.
  eof = 0.75,

  -- Distance from both ends of the window:
  -- If cursorline is in this range when pressing <CR> in search, `adjust_eof()`
  -- will be executed. When nil, scroll on search is disabled.
  search1 = 1,
}
```

## 🤝 Integrations

I didn't refer to it above but integration options can be included in the second
argument of the `hook()` function.

### [nvim-hlslens](https://github.com/kevinhwang91/nvim-hlslens/)

By specifying `{ hlslens = true }` you can enable hlslens integration. But it's
already included in the 'nice' default for `n` and `N`! So you don't have to do
it manually. (If nvim-hlslens is not installed, it is just ignored.)

```lua
-- This is perfect.
-- Ensure vim.g.loaded_nvim_hlslens == 1.
vim.keymap.set({ 'n', 'x' }, 'n', function() require('nice-scroll').hook('n') end)
vim.keymap.set({ 'n', 'x' }, 'N', function() require('nice-scroll').hook('N') end)
```

## 🙏 Credits

- I learned a lot from
  [nvim-hlslens](https://github.com/kevinhwang91/nvim-hlslens/), thank you! This
  is a definitely awesome plugin, please check it out!
- In the introduction video above, I use
  [Rosé Pine Moon](https://github.com/rose-pine/neovim). It's one of my
  favorites.
