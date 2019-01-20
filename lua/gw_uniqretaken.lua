require "stringadd"

local execcmd = function(command)
   local handle = io.popen(command, "r")
   local content = handle:read("*all")
   handle:close()
   return content
end

local ucs2c = function(ucs)
   --print("??",ucs);
   local hex = ucs:match("u(%x+)");
   if (not hex) then return "〓"; end
   return utf8.char(tonumber("0x"..hex));
end


local crawl_table = function()
   local fp = io.open("../gwdiff/p.retaken.dat","r");
   local retaken = {};
   for line in fp:lines() do
      (function(line) 
         local r = line:split("\t");
         if (not r or not r[1]) then return end
         local dkw = r[1]:match("^dkw%-[hd0-9]+");
         if (not dkw) then return end
         retaken[dkw] = line;
      end)(line)
   end
   fp:close();

   for k, v in pairs(retaken) do
      print(v);
   end
end

crawl_table();

