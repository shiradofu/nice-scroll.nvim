local K = {}

local function wrap_fn(fn, name)
  return function()
    K.prepare()
    fn()
    require('nice-scroll')[name]()
  end
end

local function wrap_str(str, name, countable)
  local rhs = '%s'
  if countable then
    rhs = "<Cmd>exe 'normal! ' . b:count1 . '%s'<CR>"
  end

  rhs = '<Cmd>lua require("nice-scroll").prepare()<CR>'
    .. rhs:format(str)
    .. ('<Cmd>lua require("nice-scroll").%s()<CR>'):format(name)

  if countable then
    rhs = '<Cmd>let b:count1 = v:count1<CR>' .. rhs .. '<Cmd>unlet b:count1<CR>'
  end

  return rhs
end

function K.search(wrapped, countable)
  if type(wrapped) == 'function' then
    return wrap_fn(wrapped, 'search')
  end
  if type(wrapped) == 'string' then
    return wrap_str(wrapped, 'search', countable)
  end
end

function K.jump(wrapped, countable)
  if type(wrapped) == 'function' then
    return wrap_fn(wrapped, 'jump')
  end
  if type(wrapped) == 'string' then
    return wrap_str(wrapped, 'jump', countable)
  end
end

return K
