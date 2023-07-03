require "stringadd"

local execcmd = function(command)
   local handle = io.popen(command, "r")
   local content = handle:read("*all")
   handle:close()
   return content
end


local glyphname = function(code)
   code = code:lower()
   if (code:match("^dh*%d+%.%d$")) then
      return "dkw-" .. code:sub(2, 6) .. ("d"):rep(tonumber(code:sub(-1)));
   end

   local name = ""
   for w in code:gmatch("u%+%x+") do
      name = name .. "-u" .. ("%x"):format(tonumber(w:sub(3), 16))
   end
   return name:sub(2)
end


local findundone = function(e0, e1)
   local done = {};
   local fp = io.open("done/done.dat","r")
   for line in fp:lines() do
      --print(line);
      local m = line:match("(dkw%-[^%.]+)%.dat");
      if (m) then done[m] = true; -- print("done", m);
      end
   end
   fp:close();
   local fp = io.open("mj1_ishii.txt","r")
   for line in fp:lines() do
      local m = line:split("\t");
      if (m[4] ~= nil and m[4]:trim() ~= "") then done[m[1]] = true; --print(m[1]);
      end
   end
   fp:close();
   local jmj = {};
   local fp = io.open("mji_00502_pickup.txt","r")
   for gline in fp:lines() do
      local line = gline:split("\t");
      local dkw = line[1];
      local koseki = line[2];
      local ucs = line[3];
      local page = (function(dkw)
        local page = dkw:trim():gsub("補", "h"):gsub("%'", "d");
        local n = page:match("%d+")
        return page:gsub(n, (page:find("^h") and "%04d" or "%05d"):format(n));
      end)(dkw);

      local alias = (function(koseki)
         local glyph = koseki:match("^%ksk%-(%d+)$");
         return glyph and ("[[koseki-%s]]"):format(glyph) or nil;
      end)(koseki);
      if (alias) then
         jmj[page] = ucs .. "/" .. alias;
      end
   end
   fp:close();
   
   local fp = io.open("done/undone.dat","r")
   for line in fp:lines() do
      line = line:trim();
      if (done[line]) then
         --print(line, jmj[line], "undone");
         --print(line, "done");
      elseif (jmj[line]) then
         local tmp = jmj[line]:split("/");
         local ucs = tmp[1]:gsub("U%+", "0x");
         local u = tonumber(ucs);
         --print(ucs, u, tonumber("0x5875\n"), tmp[2]);
         print(line, utf8.char(u), tmp[2], "undone");
      end
   end
   fp:close();
end

-- glyph定義から参照文字とストローク種別のみをカンマ区切りで返す
local findnoparts = function()
   local fp = io.open("p.nopartx2.dat","r")
   for line in fp:lines() do
      --print(line);
      local m = line:split(" ");
      local target = m[5] .. m[6];
      local dkw = m[1];
      local c = m[3];
      local glyph = m[4];
      local ret = {};

      local strokes = glyph:split("$");

      for _, stroke in ipairs(strokes) do
         if (stroke:match("^99:")) then
            local key = stroke:split(":")[8];
            local m = key:match("^u(%x+)");
            local ref = m and utf8.char(tostring("0x" .. m)) or "〓";
            ret[#ret + 1] = ref .. "[" .. key .. "]";
         else
            ret[#ret + 1] = stroke:split(":")[1];
         end
      end
      print(target, dkw, c, table.join(ret, ","));
   end
   fp:close();
end
--findundone();
findnoparts();
os.exit();

local help = function()
   print (" # " .. arg[0] .. " [mode] [start] [end]");
   print ("");
   print (" [mode] ");
   print ("  - dump: Only dump");
   print ("  - login: Login glyphwiki test");
   print ("  - exist: Access glyphwiki and dump yet-registered glyphs");
   print ("  - register: registration (with login and exist) ");
   print ();
   print (" [start][end]");
   print ("  - xml mji entry");
   print ();
end

if (#arg ~= 3) then
   help();
   return;
end

execcmd("mkdir -p ~/tmp/glyphwiki");

if ((arg[1] == "login" or (arg[1] == "register")) and (loginwiki() == nil)) then
   return;
end

local e0 = tonumber(arg[2]);
local e1 = tonumber(arg[3]);
if (e0 > e1) then
   help();
   return;
end
crawl_table(e0, e1);


if (false) then
   local glyph = "99:0:0:0:0:150:200:u72ad-01:0:0:0$99:0:0:60:0:199:95:u8278:0:0:0$99:0:0:65:80:192:190:u7530:0:0:0";
   accesswiki("dkw-11232", "[[u2283a]]");
end

--[[

【e漢字との連携】
dkw-00001は、
   http://ekanji.u-shimane.ac.jp/PrjEkanji/picture/dai/1-1000/dai000001.gif
   dkw-00366dは、
   http://ekanji.u-shimane.ac.jp/PrjEkanji/picture/dai/49001-50000/dai049965.gif
   dkw-43256ddは、
   http://ekanji.u-shimane.ac.jp/PrjEkanji/picture/dai/50001-51000/dai050476.gif
とか。
]]



