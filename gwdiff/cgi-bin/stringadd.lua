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

table.dump = function(val)
   function recursive(obj)
      if (type(obj) == "function") then
	 return ("<function>");
      end

      if (type(obj) ~= "table") then
	 return ("%q"):format(obj);
      end

      local ret = "{";
      local i = 0;
      for k, v in pairs(obj) do
	 i = i + 1;
	 if (k == i) then
	    ret = ("%s %s, "):format(ret, recursive(v));
	 else
	    ret = ("%s %q = %s, "):format(ret, k, recursive(v));
	 end
      end
      return ret .. "}";
   end
   
   print(recursive(val));
end
