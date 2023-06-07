local _MOD = {}

function _MOD:split(str, delim)
    if str == nil or str == "" then
       return {}
    end
    str = str .. delim

    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local lastPos
    for part, pos in string.gmatch(str, pat) do
       key, val = string.match(part, "(.-)%=(.*)")
       if (key) then
          result[key] = val
       else
          table.insert(result, part)
       end
       lastPos = pos
    end

    local last = string.sub(str, lastPos)
    key, val = string.match(last, "(.-)%=(.*)")

    if (key) then
       result[key] = val
    else
       table.insert(result, last)
    end
    return result
end

--[[
function _MOD:post()
   local size = os.getenv("CONTENT_LENGTH")
   local ret = ""

   for line in io.lines() do
      ret = ret .. line
   end

   return self:split(ret, "&")
end
]]
function _MOD:post()
   local query = {};

   if (os.getenv("REQUEST_METHOD") == "POST") then
      package.path = package.path .. ";./?.lua;./cgilua/?.lua"
      local post = require "cgilua.post";

      post.parsedata {
         read = function(n)
            return io.read(n);
         end,
         discardinput = function() end,
         content_type = os.getenv("CONTENT_TYPE"),
         content_length = os.getenv("CONTENT_LENGTH"),
         maxinput = 7.75 * 1024 * 1024 + 1024,
         maxfilesize = 7.75 * 1024 * 1024,
         args = query,
      };
   end

   return query;
end



function _MOD:post_json()
   local size = os.getenv("CONTENT_LENGTH")

   local ret = ""
   for line in io.lines() do
      ret = ret .. line
   end

   return ret
end

function _MOD:get()
   local ret = os.getenv("QUERY_STRING") or "";
   --print (ret);
   local s,t;

   for k in ret:gmatch("%%%x%x") do
      ret = ret:gsub("%"..k, string.char("0x" .. k:sub(2)))
   end;
   return self:split(ret, "&")
end

return _MOD;
