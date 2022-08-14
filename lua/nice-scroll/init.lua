---@class NiceScroll
---@field config NiceScroll.Config
local M = {}

---@class NiceScroll.Config
---@field default number
---@field eof number|nil
---@field search1 number|nil
M.config = {
  default = 0.25,
  eof = 0.75,
  search1 = 1,
}

---File line number, abusolute
---@class FileLineNumber
---@field eof fun(): number
---@field current fun(): number
local f = {
  eof = function()
    return vim.api.nvim_buf_line_count(0)
  end,
  current = function()
    return vim.api.nvim_win_get_cursor(0)[1]
  end,
}

---Window line number, relative to the top of the window
---@class WindowLineNumber
---@field first fun(): 1
---@field last fun(): number
---@field current fun(): number
---@field target fun(self: WindowLineNumber, n: number): number
local w = {
  first = function()
    return 1
  end,
  last = function()
    return vim.api.nvim_win_get_height(0)
  end,
  current = function()
    return vim.fn.winline()
  end,
  target = function(self, n)
    assert(type(n) == 'number' and n > 0)
    return n <= 1 and math.floor(self.last() * n) or n
  end,
}

---@param target number
---@param current number
local function exec(target, current)
  local distance = target - current

  -- Depending on the config.default value, executing M.adjust() multiple times
  -- results shaking the page. Usually, we don't call M.adjust twice or more in
  -- a row, but this behavior is a bit wired.
  -- The condition below surpress it.
  if math.abs(distance) <= 1 then
    return
  end

  if distance < 0 then
    vim.cmd(([[exe "normal! %d\<C-e>"]]):format(math.abs(distance)))
  else
    vim.cmd(([[exe "normal! %d\<C-y>"]]):format(distance))
  end
end

---Bring the current cursor line to 'nice' position.
---@param n number|'r'|nil r = reverse
function M.adjust(n)
  local d = M.config.default
  n = n and n or d
  if n == 'r' then
    n = d <= 1 and 1 - d or w.last() - d
  end
  exec(w:target(n), w.current())
end

---Bring the current cursor line to 'nice' position, but being careful not to
---raise the EOF too much.
---@param n number|'r'|nil
function M.adjust_eof(n)
  n = n and n or M.config.default
  if not M.config.eof or n == 'r' then
    M.adjust(n)
    return
  end
  local distance_from_current_to_eof = f.eof() - f.current()
  -- If M.adjust(n) would be executed, window line number of EOF is set to `_eof`.
  local _eof = w:target(n) + distance_from_current_to_eof
  local eof_target = w:target(M.config.eof)
  -- This is a line number comparison, so if it's smaller, it's over the limit.
  if _eof < eof_target then
    local eof_current = w.current() + distance_from_current_to_eof
    exec(eof_target, eof_current)
  else
    M.adjust(n)
  end
end

---Scrolling to the 'nice' position on search submitting.
local function search1()
  local limit = M.config.search1
  if not limit then
    return
  end
  if limit < 1 then
    limit = math.floor(w.last() * limit)
  end
  local c = w.current()
  limit = limit - 1
  if (c <= w.first() + limit) or (c >= w.last() - limit) then
    M.adjust_eof()
  end
end

--------------------
--                --
-- hook functions --
--                --
--------------------
local w0_saved = nil
function M._hook_prepare()
  w0_saved = vim.fn.getpos('w0')[2]
end

---Chekc if the page has scrolled between pre and post jump.
---@return boolean
local function check()
  return vim.fn.getpos('w0')[2] ~= w0_saved
end

---@param n number|'r'|nil
function M._hook_jump(n)
  if check() then
    M.adjust_eof(n)
  end
end

---@param fn function
---@param reverse boolean
local function wrap_fn(fn, reverse)
  return function()
    M._hook_prepare()
    fn()
    M._hook_jump(reverse and 'r' or nil)
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

  rhs = "<Cmd>lua require('nice-scroll')._hook_prepare()<CR>"
    .. rhs
    .. ("<Cmd>lua require('nice-scroll')._hook_jump(%s)<CR>"):format(
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
function M.hook(wrapped, opts)
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

---@param config NiceScroll.Config
function M.setup(config)
  M.config = vim.tbl_extend('force', M.config, config)

  for _, v in pairs(M.config) do
    if v then
      assert(type(v) == 'number' and v > 0)
    end
  end

  if M.config.search1 then
    local aug = vim.api.nvim_create_augroup('NiceScrollNvim', {})
    vim.api.nvim_create_autocmd('CmdlineLeave', {
      group = aug,
      pattern = '*',
      callback = function()
        local e = vim.v.event
        if
          (e.cmdtype == '/' or e.cmdtype == '?')
          and not e.abort
          and vim.fn.bufname() ~= '[Command Line]'
        then
          vim.defer_fn(search1, 0)
        end
      end,
    })
  end
end

return M
