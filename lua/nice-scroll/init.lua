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

---@param config NiceScroll.Config
function M.setup(config)
  M.config = vim.tbl_extend('force', M.config, config)

  for _, v in pairs(M.config) do
    assert(type(v) == 'number' and v > 0)
  end

  if M.config.search1 then
    local aug = vim.api.nvim_create_augroup('NiceScrollNvim', {})

    vim.api.nvim_create_autocmd('CmdlineEnter', {
      group = aug,
      pattern = '*',
      callback = function()
        local cmdtype = vim.v.event.cmdtype
        if
          (cmdtype == '/' or cmdtype == '?')
          and vim.fn.bufname() ~= '[Command Line]'
        then
          M.prepare()
        end
      end,
    })

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
          vim.defer_fn(M.search1, 0)
        end
      end,
    })

    vim.api.nvim_create_autocmd('SearchWrapped', {
      group = aug,
      pattern = '*',
      callback = function()
        vim.b.nice_scroll_wrapped = true
      end,
    })
  end
end

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

local w0_saved = nil
function M.prepare()
  w0_saved = vim.fn.getpos('w0')[2]
end

---Chekc if the page has moved between pre and post command execution.
---'w0' refers to the file's absolute line number, which is shown at the
---top of the window.
---If the page goes down, this returns positive, if goes up, returns negative.
---When `SearchWrapped` fired, the behavior becomes opposite.
---@return number
function M.check()
  local w0 = vim.fn.getpos('w0')[2]
  local c = w0 - w0_saved
  if vim.b.nice_scroll_wrapped then
    c = c * -1
  end
  vim.b.nice_scroll_wrapped = false
  return c
end

---@param n number
---@return number
local function reverse(n)
  return n <= 1 and 1 - n or w.last() - n
end

---@param target number
---@param current number
local function exec(target, current)
  local distance = target - current

  -- Depending on the config.default value, executing M.fit() multiple times
  -- results shaking the page. Usually, we don't do call M.fit twice or more
  -- in a row, but this behavior is a bit wired.
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

---Bring the current cursor line to 'nice' place.
---@param n number|'r'|nil r = reverse
function M.fit(n)
  n = n and n or M.config.default
  if n == 'r' then
    n = reverse(M.config.default)
  end
  exec(w:target(n), w.current())
end

---Bring the current cursor line to 'nice' place, but being careful not to
---raise the EOF too much.
---@param n number|nil
function M.fit_eof(n)
  n = n and n or M.config.default
  if not M.config.eof then
    M.fit(n)
    return
  end
  local distance_from_current_to_eof = f.eof() - f.current()
  -- If M.fit(n) would be executed, window line number of EOF is set to `_eof`.
  local _eof = w:target(n) + distance_from_current_to_eof
  local eof_target = w:target(M.config.eof)
  -- This is a line number comparison, so if it's smaller, it's over the limit.
  if _eof < eof_target then
    local eof_current = w.current() + distance_from_current_to_eof
    exec(eof_target, eof_current)
  else
    M.fit(n)
  end
end

---Scrolling to the 'nice' position after a directional jump like 'n' or 'N'.
---When you scroll up, it will invert the position to stop so that you can
---see where you're going to go.
---@param n number|nil
function M.directional(n)
  n = n and n or M.config.default
  local c = M.check()
  if c > 0 then
    M.fit_eof(n)
  end
  if c < 0 then
    M.fit(reverse(n))
  end
end

---Scrolling to the 'nice' position after a non-directional jump like '<C-o>' or 'g;'
---@param n number|nil
function M.jump(n)
  n = n and n or M.config.default
  if M.check() ~= 0 then
    M.fit_eof(n)
  end
end

---Scrolling to the 'nice' position after pressing Enter key to confirm search.
function M.search1()
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
    M.fit_eof()
  end
end

return M
