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
  eof = function() return vim.api.nvim_buf_line_count(0) end,
  current = function() return vim.api.nvim_win_get_cursor(0)[1] end,
}

---Window line number, relative to the top of the window
---@class WindowLineNumber
---@field first fun(): 1
---@field last fun(): number
---@field current fun(): number
---@field target fun(self: WindowLineNumber, n: number): number
local w = {
  first = function() return 1 end,
  last = function() return vim.api.nvim_win_get_height(0) end,
  current = function() return vim.fn.winline() end,
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
  if math.abs(distance) <= 1 then return end

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
  if n == 'r' then n = d <= 1 and 1 - d or w.last() - d end
  exec(w:target(n --[[@as number]]), w.current())
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
  local _eof = w:target(n --[[@as number]]) + distance_from_current_to_eof
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
  if not limit then return end
  if limit < 1 then limit = math.floor(w.last() * limit) end
  local c = w.current()
  limit = limit - 1
  if (c <= w.first() + limit) or (c >= w.last() - limit) then M.adjust_eof() end
end

--------------------
--                --
-- hook functions --
--                --
--------------------
---@class NiceScrollHook.Options
---@field reverse boolean
---@field countable boolean
---@field debug boolean

---@class NiceScrollHook.AsyncOptions
---@field timeout number
---@field reverse boolean
---@field countable boolean
---@field debug boolean

local H = {}

H.w0_saved = nil
H.bufnr_saved = nil
H.default_timeout = 1000000

---@generic T : NiceScrollHook.Options|NiceScrollHook.AsyncOptions
---@param hooked string|function
---@param opts T|nil
---@return T
function H.prepare_opts(hooked, opts)
  -- Nice default for 'n' and 'N'
  if hooked == 'n' or hooked == 'N' then
    opts = vim.tbl_extend('keep', opts, { countable = true })
    if hooked == 'N' then
      opts = vim.tbl_extend('keep', opts, { reverse = true })
    end
  end
  return opts
end

function H.save_current_pos()
  H.w0_saved = vim.fn.getpos('w0')[2]
  H.bufnr_saved = vim.api.nvim_get_current_buf()
end

---@param win_id number
local function is_floating_win(win_id)
  return vim.api.nvim_win_get_config(win_id).relative ~= ''
end

---@param opts NiceScrollHook.AsyncOptions
function H.prepare_async(opts)
  local cursor_moved =
    vim.api.nvim_create_augroup('NiceScrollHookCursorMoved', {})
  local timer = vim.defer_fn(
    function() vim.api.nvim_clear_autocmds { group = cursor_moved } end,
    opts.timeout or H.default_timeout
  )
  vim.api.nvim_create_autocmd('CursorMoved', {
    once = true,
    group = cursor_moved,
    callback = function()
      if is_floating_win(vim.api.nvim_get_current_win()) then
        timer:stop()
        timer:close()
        local win_enter =
          vim.api.nvim_create_augroup('NiceScrollHookWinEnter', {})
        -- fires after leaving the floating window and entering normal window
        vim.api.nvim_create_autocmd('WinEnter', {
          once = true,
          group = win_enter,
          callback = function()
            -- fires right after upper 'WinEnter' fired
            vim.api.nvim_create_autocmd('CursorMoved', {
              once = true,
              group = cursor_moved,
              callback = function()
                vim.defer_fn(
                  function()
                    vim.api.nvim_clear_autocmds { group = cursor_moved }
                  end,
                  100
                )
                -- this is the main purpose: adjust the current line p
                vim.api.nvim_create_autocmd({ 'CursorMoved', 'WinScrolled' }, {
                  once = true,
                  group = cursor_moved,
                  callback = function() H.jump(opts) end,
                })
              end,
            })
          end,
        })
      else
        H.jump(opts)
      end
    end,
  })
end

---@param hooked string|function
---@param opts NiceScrollHook.Options|NiceScrollHook.AsyncOptions
---@return any
function H.do_hooked(hooked, opts)
  local ret = nil
  if type(hooked) == 'function' then ret = hooked() end
  if type(hooked) == 'string' then
    if opts.countable then
      local count1 = tostring(vim.v.count1)
      if hooked:find '%%d' then
        hooked = hooked:format(count1)
      else
        if hooked:find '<[Cc][Mm][Dd]>' == 1 then
          hooked = hooked:sub(1, 5) .. count1 .. hooked:sub(6, -1)
        elseif hooked:find ':<[Cc]%-[Uu]>' == 1 then
          hooked = hooked:sub(1, 6) .. count1 .. hooked:sub(7, -1)
        elseif hooked:find ':' == 1 then
          hooked = hooked:sub(1, 1) .. count1 .. hooked:sub(2, -1)
        else
          hooked = count1 .. hooked
        end
      end
    end
    hooked = hooked:gsub('<', [[\<]]):gsub('"', [[\"]])
    local cmd = string.format('execute "normal! %s"', hooked)
    if opts.debug then vim.api.nvim_echo({ { cmd, 'None' } }, true, {}) end
    local ok, err =
      pcall(vim.cmd, string.format('execute "normal! %s"', hooked))
    if not ok then vim.api.nvim_echo({ { err, 'ErrorMsg' } }, true, {}) end
  end
  return ret
end

---@return boolean
function H.check()
  local is_scrolled = vim.fn.getpos('w0')[2] ~= H.w0_saved
  local is_buf_changed = vim.api.nvim_get_current_buf() ~= H.bufnr_saved
  return is_scrolled or is_buf_changed
end

---@param opts NiceScrollHook.Options|NiceScrollHook.AsyncOptions
function H.jump(opts)
  if H.check() then M.adjust_eof(opts.reverse and 'r' or nil) end
end

---@param hooked string|function
---@param opts NiceScrollHook.Options|nil
function M.hook(hooked, opts)
  opts = H.prepare_opts(hooked, opts or {})
  H.save_current_pos()
  local ret = H.do_hooked(hooked, opts)
  H.jump(opts)
  local ok, hlslens = pcall(require, 'hlslens')
  if ok then hlslens.start() end
  return ret
end

---@param hooked string|function
---@param opts NiceScrollHook.AsyncOptions|nil
function M.hook_async(hooked, opts)
  opts = H.prepare_opts(hooked, opts or {})
  H.save_current_pos()
  H.prepare_async(opts)
  H.do_hooked(hooked, opts)
end

---@param config NiceScroll.Config
function M.setup(config)
  M.config = vim.tbl_extend('force', M.config, config)

  for _, v in pairs(M.config) do
    if v then assert(type(v) == 'number' and v > 0) end
  end

  if M.config.search1 then
    local aug = vim.api.nvim_create_augroup('NiceScrollSearch1', {})
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
