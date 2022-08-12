local K = {}

local function wrap_fn(fn, name)
  return function()
    K.prepare()
    fn()
    require('nice-scroll')[name]()
  end
end

---@param str string
---@param name string
---@param countable boolean
local function wrap_str(str, name, countable)
  local rhs = str
  if countable then
    if str:find '<[Cc][Mm][Dd]>' then
      local last = str:find '<[Cc][Rr]>' - 1
      rhs = ("<Cmd>exe b:count1 . '%s'<CR>"):format(str:sub(#'<Cmd>' + 1, last))
    else
      rhs = ("<Cmd>exe 'normal! ' . b:count1 . '%s'<CR>"):format(str)
    end
  end

  rhs = '<Cmd>lua require("nice-scroll").prepare()<CR>'
    .. rhs
    .. ('<Cmd>lua require("nice-scroll").%s()<CR>'):format(name)

  if countable then
    rhs = '<Cmd>let b:count1 = v:count1<CR>'
      .. rhs
      .. '<Cmd>silent! unlet b:count1<CR>'
  end

  return rhs
end

local function handle_options_str(rhs, options)
  if vim.tbl_contains(options, 'hlslens') then
    rhs = rhs .. "<Cmd>lua require('hlslens').start()<CR>"
  end
  return rhs
end

function K.directional(wrapped, countable, options)
  options = options or {}

  if type(wrapped) == 'function' then
    return wrap_fn(wrapped, 'directional')
  end
  if type(wrapped) == 'string' then
    local rhs = wrap_str(wrapped, 'directional', countable)
    return handle_options_str(rhs, options)
  end
end

function K.jump(wrapped, countable, options)
  options = options or {}

  if type(wrapped) == 'function' then
    return wrap_fn(wrapped, 'jump')
  end
  if type(wrapped) == 'string' then
    local rhs = wrap_str(wrapped, 'jump', countable)
    return handle_options_str(rhs, options)
  end
end

return K