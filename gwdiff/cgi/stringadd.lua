-- return iterator
string.split_it = function(str, sep)
        if str == nil then return nil end
        assert(type(str) == "string", "str must be a string")
        assert(type(sep) == "string", "sep must be a string")
        return string.gmatch(str, "[^" .. sep .. "]+")
end

-- return table
string.split = function(str, sep)
   local ret = {}
   for seg in string.split_it(str, sep) do
      ret[#ret+1] = seg
   end
   return ret
end

--[[* join *]]--
table.join = function (tbl, sep)
   local ret
   for n, v in pairs(tbl) do
      local seg = tostring(v)
      if ret == nil then
         ret = seg
      else
         ret = ret .. sep .. seg
      end
   end
   return ret
end

string.trim = function(str)
   return str:match("^%s*(.-)%s*$");
end
