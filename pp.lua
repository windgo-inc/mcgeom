-- look for packages locally in lpeg and video
-- make sure we have pack and unpack

local t = { _did_it = false }
local _readers = {}

if not t._did_it then
  package.path = "./lpeg/?.lua;./video/?.lua;./fun/?.lua;" .. package.path
  t._did_it = true

  -- already done
  -- require 'fun' () -- PRESTO !

  if table.iread == nil then
    local _iread = function (_, t)
      local _readers = _readers
      return setmetatable({}, { __index = function (_, i) return t[i] end })
    end

    rawset(table, 'iread', _iread)
  end

  if table.pack == nil then
    function table.pack (...) return {...} end
  end

  if table.unpack == nil then
    rawset(table, 'unpack', unpack)
  end

  if table.debug_print == nil then
    local function _tdbgp (t, indent)
      if indent == nil then indent = 0 end
      local inds = string.rep(' ', indent)
      local indsb = inds..'}'

      for k, v in pairs(t) do
        local indsk = inds..tostring(k)
        if type(v) == 'table' then
          if next(v) == nil then
            print(indsk..' {}')
          else
            print(indsk..' {')
            _tdbgp(v, indent + 2)
            print(indsb)
          end
        else
          print(indsk..' '..tostring(v))
        end
      end
    end

    rawset(table, 'debug_print', _tdbgp)
  end

  if _G.unfurl == nil then
    local function unfurl_g (iter, state)
      -- try to get the head element.
      local status, next_p = pcall (head, state)
      if not status then return nil end

      return tail(state), next_p
    end

    local function unfurl_G (iter)
      return unfurl_g, iter, iter
    end

    local function unfurl (iter)
      local status, head_p = pcall (head, iter)
      if not status then return nil end

      return head_p, unfurl (tail (iter))
    end

    local _chaini_chunksize = 8

    local function chaini (iter)
      local csz = _chaini_chunksize
      local head_t = totable(take(csz, iter))
      if #head_t == csz then
        return chain (chain (unpack (head_t)), chaini (drop (csz, iter)))
      elseif #head_t == 0 then
        return iter''
      else
        return chain (unpack (head_t))
      end
    end

    _G.unfurl_G = unfurl_G
    _G.chaini = chaini

    _G.unfurl = function (nv, v)
      if type(nv) == 'number' then
        return unfurl (take (nv, v))
      else
        return unfurl (nv)
      end
    end
  end

  if _G.indexer == nil then
    local _indexer_mt = { __call = function (u, i) return i, u[1][i] end }

    -- also accepts a shorthand for mapping to ranges.
    --
    -- indexer(mytable) will return a function which maps keys to the associated
    -- values from mytable. indexer(mytable, ...) with select('#', ...) ~= 0 is a
    -- shorthand for map (indexer(mytable), range (...)), since iterating over
    -- ranges is trivial and commonplace and thus deserves concise representation.
    --
    --
    local function indexer (t, ...)
      local na = select('#', ...)
      if na > 0 then
        return map (indexer(t), range (...))
      else
        return setmetatable ({ t }, _indexer_mt)
      end
    end

    _G.indexer = indexer
  end

  -- TODO : Make this reasonable for big n
  if _G.droptail == nil then
    local function droptail (n, iter)
      local i_t = totable (iter)
      local m = # i_t
      local e = m - n + 1
      for i = e, m do i_t[i] = nil end
      return i_t
    end

    _G.droptail = droptail
  end

  if _G.take_args == nil then
    local function take_args (n, ...)
      local t = {}
      for i = 1, n do t[i] = select(i, ...) end
      return t
    end

    _G.take_args = take_args
  end

  if _G.join_key == nil then
    local totable, take_args, take, drop, concat = totable, take_args, take, drop, concat

    local function join_key (f, n, it)
      local n, n1, f = n, n + 1, f
      return map (function (...)
        return f (take_args (n, ...)), select(n1, ...)
      end, it)
    end

    _G.join_key = function (df, n, it)
      if type(df) == 'string' then
        local delimiter = df
        local totable, concat = totable, concat
        return join_key(function (t) return concat (t, delimiter) end, n, it)
      else
        return join_key(df, n, it)
      end
    end
  end

  if _G.mapset == nil then
    local tomap, zip, duplicate = tomap, zip, duplicate
    local function mapset (it)
      return tomap (zip (it, duplicate (true)))
    end
    
    _G.mapset = mapset
  end

  -- local variables snapshot for module cross dependency handling.
  if _G.locals == nil then
    local getlocal, rawset = debug.getlocal, rawset
    local function locals ()
      local t, i, getlocal, rawset = {}, 1, getlocal, rawset
      repeat
        local ln, lv = getlocal(2, i)
        if ln == nil then break end

        rawset(t, ln, lv)

        i = i + 1
      until false
      return t
    end

    _G.locals = locals
  end
end

return t

