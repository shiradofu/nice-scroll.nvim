local M = {}

M.config = {
  default = 0.3,
  eof = 0.7,
  search1 = 1,
}

function M.setup(config)
  M.config = vim.tbl_extend('force', M.config, config)

  for _, v in pairs(M.config) do
    assert(type(v) == 'number' and v > 0)
  end

  if M.config.search1 then
    local aug = vim.api.nvim_create_augroup('NiceScrollNvim', {})

    vim.api.nvim_create_autocmd('CmdlineEnter', {
      pattern = '*',
      group = aug,
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
      pattern = '*',
      group = aug,
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
      pattern = '*',
      group = aug,
      callback = function()
        vim.b.nice_scroll_wrapped = true
      end,
    })
  end
end

-- File line number, abusolute
local f = {
  eof = function()
    return vim.api.nvim_buf_line_count(0)
  end,
  current = function()
    return vim.api.nvim_win_get_cursor(0)[1]
  end,
}

-- Window line number, relative to the top of the window
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

-- If page goes down, returns 1
-- If page goes up, returns -1
function M.check()
  local c = 0
  local w0 = vim.fn.getpos('w0')[2]
  if w0 > w0_saved then
    c = 1
  end
  if w0 < w0_saved then
    c = -1
  end
  if vim.b.nice_scroll_wrapped then
    c = c * -1
  end
  vim.b.nice_scroll_wrapped = false
  return c
end

local function reverse(n)
  return n <= 1 and 1 - n or w.last() - n
end

local function cmdf(s, ...)
  vim.cmd(string.format(s, ...))
end

local function exec(target, current)
  local distance = target - current
  if distance < 0 then
    cmdf([[exe "normal! %d\<C-e>"]], math.abs(distance))
  else
    cmdf([[exe "normal! %d\<C-y>"]], distance)
  end
end

---@param n number|'r' r = reverse
function M.fit(n)
  n = n and n or M.config.default
  if n == 'r' then
    n = reverse(M.config.default)
  end
  exec(w:target(n), w.current())
end

function M.fit_eof(n)
  n = n and n or M.config.default
  if not M.config.eof then
    M.fit(n)
    return
  end
  local distance_from_current_to_eof = f.eof() - f.current()
  -- If M.fit(n) is done, window line number of EOF will be _eof.
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

function M.jump(n)
  n = n and n or M.config.default
  if M.check() ~= 0 then
    M.fit_eof(n)
  end
end

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
