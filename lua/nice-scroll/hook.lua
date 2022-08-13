local nice_scroll = require 'nice-scroll'
local H = {}

local w0_saved = nil
function H._prepare()
  w0_saved = vim.fn.getpos('w0')[2]
end

---Chekc if the page has moved between pre and post jump.
---@return boolean
local function check()
  return vim.fn.getpos('w0')[2] ~= w0_saved
end

---@param n number|'r'|nil
function H._jump(n)
  if check() then
    nice_scroll.fit_eof(n)
  end
end

---@param fn function
---@param reverse boolean
local function wrap_fn(fn, reverse)
  return function()
    H._prepare()
    fn()
    H._jump(reverse and 'r' or nil)
  end
end

---@param str string
---@param reverse boolean
---@param countable boolean
local function wrap_str(str, reverse, countable)
  local rhs = str
  if countable then
    if str:find '<[Cc][Mm][Dd]>' then
      local last = str:find '<[Cc][Rr]>' - 1
      rhs = ("<Cmd>exe b:count1 . '%s'<CR>"):format(str:sub(#'<Cmd>' + 1, last))
    else
      rhs = ("<Cmd>exe 'normal! ' . b:count1 . '%s'<CR>"):format(str)
    end
  end

  rhs = "<Cmd>lua require('nice-scroll.hook')._prepare()<CR>"
    .. rhs
    .. ("<Cmd>lua require('nice-scroll.hook')._jump(%s)<CR>"):format(
      reverse and "'r'" or ''
    )

  if countable then
    rhs = '<Cmd>let b:count1 = v:count1<CR>'
      .. rhs
      .. '<Cmd>silent! unlet b:count1<CR>'
  end

  return rhs
end

---@class NiceScrollHook.Options
---@field reverse boolean
---@field countable boolean
---@field hlslens boolean

---@param rhs string
---@param opts NiceScrollHook.Options
---@return string
local function handle_options_str(rhs, opts)
  if opts.hlslens and vim.g.loaded_nvim_hlslens == 1 then
    rhs = rhs .. "<Cmd>lua require('hlslens').start()<CR>"
  end
  return rhs
end

---@param wrapped string|function
---@param opts NiceScrollHook.Options|nil
function H.hook(wrapped, opts)
  -- Nice default for 'n' and 'N'
  if (wrapped == 'n' or wrapped == 'N') and not opts then
    opts = { countable = true, hlslens = true }
    if wrapped == 'N' then
      opts.reverse = true
    end
  end

  opts = opts or {}

  if type(wrapped) == 'function' then
    return wrap_fn(wrapped, opts.reverse)
  end
  if type(wrapped) == 'string' then
    local rhs = wrap_str(wrapped, opts.reverse, opts.countable)
    return handle_options_str(rhs, opts)
  end
end

return H
