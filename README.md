<p align="center">
  <h1 align="center">👍 nice-scroll.nvim</h2>
</p>

<p align="center">
  Happiness begins with a comfortable scroll.
</p>

https://user-images.githubusercontent.com/43514606/184519525-0cbe7619-b4cf-4c9e-89fe-dd99884b7a92.mov

This is an alpha stage plugin, so it still might not be so 'nice'.

## ✊ Motivation

Neovim has really strong search and jump features, but they're too strong for me
to follow the cursor. It's hopping and skipping around the editor like an
innocent child. That's fine for a child, but not so for a cursor.

This plugin can hook into cursor jumps and scroll the page to bring it where it
is easy to see. This could be applied to traversing search resutls by `n`/`N` ,
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

Note: The configs below are just examples. This plugins does not provide default
key mappings.

### Base Functions

#### `require('nice-scroll').fit()`

`fit()` brings current line to the 'nice' position (default is the quarter of
the window from the top of it).

#### `require('nice-scroll').fit_eof()`

If you execute `fit()` near the EOF, it raises too much and the visible range of
the file would be quite small. To prevent this, `fit_eof()` pays attention to
the EOF and adjust the scroll. By default, it will keep the EOF out of the 3/4
range of the window.

#### keymaps

You can set keymaps like this and manually adjust the scroll position. These are
kind a collegues of `zz`, `zt`, or `zb`.

```lua
vim.keymap.set({'n', 'x' }, 'zh', "<Plug>(nice-scroll-fit)")

-- Reverse version: See `hook()`'s second argument description for details.
vim.keymap.set({'n', 'x' }, 'zl', "<Plug>(nice-scroll-fit-r)")

-- EOF attentive version
vim.keymap.set({'n', 'x' }, 'zh', "<Plug>(nice-scroll-fit-eof)")

-- Specifying poistion
-- This will bring the cursorline to 10 line below the top of the window
vim.keymap.set({'n', 'x' }, 'zh', function() require('nice-scroll').fit(10) end)
```

#### Vim commands

Vim commands `NiceScrollFit` and `NiceScrollFitEof` are also available.

### Hooking into Jumps

#### `require('nice-scroll').hook()`

You can hook into a cursor jump and execute `fit_eof()` by `hook()` function.

Note: `fit_eof()` will be executed **only when the jump had the page scrolled**.

This function wraps a string or a lua function that is taken as the first
argument and returns it. This can be assigned to keymap rhs directly, so you can
do the following:

```lua
local ns = require('nice-scroll')
vim.keymap.set({ 'n', 'x' }, 'g;', ns.hook('g;'))
vim.keymap.set({ 'n', 'x' }, '[q', ns.hook('<Cmd>cprev<CR>'))
vim.keymap.set({ 'n', 'x' }, ']e', ns.hook(vim.diagnostic.goto_next))
```

`hook()` takes the optional second argument, and it contains:

```lua
-- default values
{
  -- If true, mappings using v:count1 like 3g; can be used.
  -- This has effect only on string mappings.
  countable = false,
  -- If true, the position where the cursorline will be moved is inverted.
  -- Suppose you configure the plugin to move the cursorline 10 lines below
  -- from the top of the window. With this option, cursorline will moved to
  -- 10 lines above from the bottom of the winodw.
  -- This is useful when scrolling up continuously like `N`.
  reverse = false,
}
```

example:

```lua
vim.keymap.set({ 'n', 'x' }, 'g,', ns.hook('g,', { countable = true }))
vim.keymap.set({ 'n', 'x' }, ']q', ns.hook('<Cmd>cnext<CR>', { countable = true }))
```

##### 'nice' defaults for `n` and `N`

Hooking into `n` and `N` are quite usual usecases, so the following defaults are
set to the options.

```lua
-- for `n`
{ countable = true, reverse = false }

-- for `N`
{ countable = true, reverse = true }
```

### Scroll on Search

If `search1` property of the configuration table is set, and the cursorline is
in specified range, `fit_eof()` will be executed on submitting search.

## 💪 Configuration

The values below are default.

```lua
-- All options accepts positive numbers.
-- n >= 1: n is considered as fixed number of lines.
-- n < 1: n is considered as ratio against the current window height.
require('nice-scroll').setup {

  -- Distance from the top end of the window:
  -- `fit()` will move the cursorline to this position.
  default = 0.25,

  -- Distance from the top end of the window:
  -- `fit_eof()` keep the EOF out of this range.
  -- If nil is set, `fit_eof()` always executes `fit()`.
  eof = 0.75,

  -- Distance from the both end of the window:
  -- If cursorline is in this range when pressing <CR> in search, `fit_eof()`
  -- will be executed.
  search1 = 1,
}
```

## 🤝 Integrations

I didn't refer to it above but integration options can be included in the second
argument of the `hook()` function.

### [nvim-hlslens](https://github.com/kevinhwang91/nvim-hlslens/)

By specifying `{ hlslens = true }` as the option you can enable integration. But
it's alreadly included into the 'nice' default for `n` and `N`! So you don't
have to do it manually. (If nvim-hlslens is not installed, it is just ignored.)

```lua
-- This is perfect.
-- Ensure vim.g.loaded_nvim_hlslens == 1 before these are loaded.
local ns = require('nice-scroll')
vim.keymap.set({ 'n', 'x' }, 'n', ns.hook('n'))
vim.keymap.set({ 'n', 'x' }, 'N', ns.hook('N'))
```

## 🙏 Credits

I learned a lot from
[nvim-hlslens](https://github.com/kevinhwang91/nvim-hlslens/), thank you! This
is definitely awesome plugin, plese check it out!
