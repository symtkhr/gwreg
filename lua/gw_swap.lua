require "stringadd"

local execcmd = function(command)
   local handle = io.popen(command, "r")
   local content = handle:read("*all")
   handle:close()
   return content
end

local accesswiki = function(page, glyph, c, retake)

   print("#####success", page, c, glyph, retake);

   local timestump = os.time();

   local cmd = "curl -X GET -w '\\n'"
   cmd = cmd .. (" 'https://glyphwiki.org/wiki/%s?action=swap' "):format(page);
   cmd = cmd .. " -b gwcookie.txt"
   cmd = cmd .. (" > ~/tmp/glyphwiki/%s.dat"):format(page);

   print(cmd);

   if (arg[1] == "register") then
      execcmd(cmd);
      execcmd("sleep 1");
   end
end

local loginwiki = function()

   local cmd = "curl -w '\\n'"
      .. " http://glyphwiki.org/wiki/Special:Userlogin"
      .. " -d 'action=page'"
      .. " -d 'buttons=ログイン'"
      .. " -d 'name=mtnest'"
      .. " -d 'page=Special:Userlogin'"
      .. " -d 'password=s57sep'"
      .. " -d 'returnto=Special:Userlogout'"
      .. " -d 'type=login'"
      .. " -b gwcookie.txt"
      .. " -c gwcookie.txt"
   print(cmd);
   local t = execcmd(cmd);
   print(t);
   return t:find("ログイン成功");
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

--版1: dkw2ucs.txtのとおりに登録する
local dkw2ucs = function(line)
    if (line == "") then return; end 
    local data = line:split("#");
    if (data[2]) then
       if (data[2]:find("removed") or
           data[2]:find("missing") or
           data[2]:find("moved")) then
          return;
       end
   end

   local tbl = data[1]:trim():split(" ");
   local code = tbl[1];

   if (code < "D19090") then return; end
   if ("D19100" < code) then return; end

   local page = glyphname(code)
   local alias = "[[" .. glyphname(tbl[5]) .. "]]"
   accesswiki(page, alias);
   return;
end

--版1: dkw2ucs.txtのとおりに登録する
local crawl_table = function()
   local fp = io.open("dkw2ucs.txt","r")
   for line in fp:lines() do
      dkw2ucs(line);
   end
   fp:close();
end

--版2: mj.00502.xmlから直接登録する
local pickups = function(buff)
   local dkw = buff:match("<大漢和>([^<]+)</大漢和>");
   if (not dkw) then return end
   local ucs = buff:match("<対応するUCS[^>]->([^<]+)</対応するUCS>");
   local font = buff:match("<実装した[^>]->([^<]+)</実装した");
   local koseki = buff:match("<戸籍統一文字番号([^<]+)<");
   if (font == nil or ucs==font) then  font = "" end
   if (ucs:sub(3) == font:sub(1, ucs:len() - 2)) then
      font = "U+" .. font:gsub("_", "U+")
      ucs = ""
   end
   --print(dkw, koseki, font, ucs);
   local page = (function(dkw)
         local page = dkw:gsub("補", "h"):gsub("%'", "d");
         local n = page:match("%d+")
         return "dkw-" .. page:gsub(n, (page:find("^h") and "%04d" or "%05d"):format(n));
   end)(dkw);

   local alias = (function(koseki)
         local glyph = koseki:match("^%>(%d+)$");
         return glyph and ("[[koseki-%s]]"):format(glyph) or nil;
   end)(koseki);
   if (alias) then
      accesswiki(page, alias);
   end
end

--版2: mj.00502.xmlから直接登録する
local crawl_table = function(e0, e1)
   local fp = io.open("./mji.00502/mji.00502.xml")

   local buff = "";
   local i = 1;
   for line in fp:lines() do
      if (line:find("<MJ文字情報>")) then buff = ""; end
      buff = buff .. line:trim();
      if (line:find("</MJ文字情報>")) then
         if (e0 <= i) then
            pickups(buff);
         end
         i = i + 1;
         if (e1 < i) then break; end
      end
   end
end

--版3: TSVから間接登録する
local pickups = function(buff)
   line = buff:split("\t");
   local dkw = line[1];
   local koseki = line[2];
   local incl = line[4];
   local page = glyphname(dkw);
   local alias = (function(koseki)
      local glyph = koseki:match("^%>(%d+)$");
      return glyph and ("[[koseki-%s]]"):format(glyph) or nil;
   end)(koseki);

   -- ついでにreplaceもしていたが複雑すぎるので分離
   if (false) then
      if (incl ~= "/" and alias) then
         local parts = incl2array(incl);
         if (parts == nil) then return; end
         
         --登録済みチェックはここでやる
         local cmd = "curl -w '%{http_code}' http://glyphwiki.org/glyph/" .. page .. ".50px.png -o /dev/null -s"
      
         if (execcmd(cmd) ~= "404") then
            return;
         end

         return replace_parts(alias:sub(3,-3),parts, page);
      end
   end

   if(true) then
      if (alias == nil) then return end
      accesswiki(page, alias);
   end
end

--版3: TSVから間接登録する
local crawl_table = function(e0, e1)
   local fp = io.open("../kids/mj0502_pickup2.txt","r"); --のちのmj1_ishii.txt
   local i = 0;
   for line in fp:lines() do
      i = i + 1;
      if (e0 <= i) then pickups(line) end
      if (e1 <= i) then break end
   end
   fp:close();
end

--ucsからdkwを得る
local u2d, d2u = (function()
   local p = {};
   local p0 = {};
   local fp = io.open("kdbonly.txt","r")
   for line in fp:lines() do
      local data = line:trim():split(",");
      local c = data[1];
      local dkw = data[2];
      if (dkw ~= nil) then 

         local page = "dkw-" ..(function(dkw)
               local page = dkw:trim():gsub("補", "h"):gsub("%'", "d");
               local n = page:match("%d+")
               return page:gsub(n, (page:find("^h") and "%04d" or "%05d"):format(n));
         end)(dkw);
         local ucs = ("u%x"):format(utf8.codepoint(c));
         p[ucs] = page;
         p0[page] = ucs;
      end
   end
   return p, p0;
end)()

--ucsからdkwを得る
local jmj;
local ksk;
local ucs2dkw = function(key)
   if (jmj ~= nil) then
      return jmj[key];
   end
   jmj = {};
   ksk = {};
   local fp = io.open("mji_00502_pickup.txt","r")
   for gline in fp:lines() do
      local line = gline:split("\t");
      local dkw = line[1];
      local koseki = line[2];
      local ucs = line[3]:lower():gsub("^u%+", "u");
      local page = (function(dkw)
        local page = dkw:trim():gsub("補", "h"):gsub("%'", "d");
        local n = page:match("%d+")
        return page:gsub(n, (page:find("^h") and "%04d" or "%05d"):format(n));
      end)(dkw);

      local alias = (function(koseki)
         local glyph = koseki:match("^%ksk%-(%d+)$");
         return glyph and ("[[koseki-%s]]"):format(glyph) or nil;
      end)(koseki);
      jmj[ucs] = jmj[ucs] and jmj[ucs] .. "," .. page or page;
      -- print("jmj", ucs, jmj[ucs]);
      if (alias) then
         jmj[alias] = page;
         ksk[page] = {koseki=alias, c=ucs};
      else
         ksk[page] = {koseki="jmj",c=ucs};
      end
   end
   fp:close();
   return jmj[key];
end
ucs2dkw("dummy");

--版4: reg.datのとおりに登録する
local pickups = function(buff)
   line = buff:split("\t");
   if (#line < 2) then  return; end
   local dkw = line[1];
   local c = line[2];
   local glyph = line[3];
   local retake = line[4] and line[4] == "retake"

   if (dkw:match("^dkw%-")==nil and dkw:match("^u%x") == nil) then
      return
   end
   if (c == "〓") then
      c = d2u[dkw] or ksk[dkw].c;
   end
   --print(c, dkw);
   if (c:match("^u%x+")) then
      local ucs = "0x" .. c:match("^u(%x+)");
      c = utf8.char(tonumber(ucs));
   end
   if (dkw == "dkw-xxxxx") then
      local ucs = ("u%x"):format(utf8.codepoint(c));
      dkw = u2d[ucs] or jmj[ucs];
   end

   accesswiki(dkw, glyph, c, retake);

end

local crawl_table = function(e0, e1)
   local pages = {
      "u24285-ue0102", --"u2d17c",
      "u2d260", "u2d260-ue0101", "u2d5c7", "u2d5d5-ue0101", "u2d612", "u2d6b6-ue0101", "u2d6b6-ue0103", "u2d6dd-ue0101", "u2d8e2", "u2dc26", "u2df59", "u2df90", "u2dff5", "u2dff5-ue0101", "u2dff6", "u2e257", "u2e439", "u2e4fc", "u2e672", "u2e6e1", "u2e8a8", "u2ea3d", "u2ea41-ue0102", "u2ebc5", "u2ebc7", "u2ebcc"};
   for _,page in ipairs(pages) do
      accesswiki(page);
   end
end

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


