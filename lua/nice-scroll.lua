local M = {}

M.config = {
  default = 0.25,
  eof = 0.75,
}

function M.setup(config)
  M.config = vim.tbl_extend('force', M.config, config)

  vim.keymap.set(
    'n',
    '<Plug>(nice-scroll-force)',
    '<Cmd>lua require("nice-scroll").force()<CR>'
  )
  vim.keymap.set(
    'n',
    '<Plug>(nice-scroll-moderate)',
    '<Cmd>lua require("nice-scroll").moderate()<CR>'
  )
  vim.keymap.set(
    'n',
    '<Plug>(nice-scroll-search)',
    '<Cmd>lua require("nice-scroll").search()<CR>'
  )
  vim.keymap.set(
    'n',
    '<Plug>(nice-scroll-jump)',
    '<Cmd>lua require("nice-scroll").jump()<CR>'
  )
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
    return vim.fn.winline '.'
  end,
  target = function(self, n, is_reverse)
    assert(type(n) == 'number' and n > 0)
    if n <= 1 then
      return math.floor(self.last() * (is_reverse and 1 - n or n))
    end
    return is_reverse and self.last() - n or n
  end,
}

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

function M.force(n, is_reverse)
  n = n and n or M.config.default
  exec(w:target(n, is_reverse), w.current)
end

function M.moderate(n)
  if not M.config.eof then
    M.force(n)
    return
  end
  local distance_from_current_to_eof = f.eof - f.current
  -- If M.force(n) is done, window line number of EOF will be _eof.
  local _eof = w:target(n) + distance_from_current_to_eof
  local eof_target = w:target(M.config.eof)
  -- This is a line number comparison, so if it's smaller, it's over the limit.
  if _eof < eof_target then
    local eof_current = w.current + distance_from_current_to_eof
    exec(eof_target, eof_current)
  else
    M.force(n)
  end
end

function M.search(n, is_reverse)
  if not is_reverse and w.current() == w.last() then
    M.moderate(n)
  end
  if is_reverse and w.current() == w.first() then
    M.force(n, true)
  end
end

function M.jump(n)
  if w.current() == w.last() or w.current() == w.first() then
    M.moderate(n)
  end
end

return M
