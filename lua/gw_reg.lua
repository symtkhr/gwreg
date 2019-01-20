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

local getjson = function(page)
   local cmd = "curl -w '%{http_code}' http://glyphwiki.org/json?name=" .. page;
   cmd = cmd .. " -s -S"
   print(cmd);
   local ret = execcmd(cmd);
   local m = ret:match('"data":%"([^%"]+)%"');
   local c = ret:match('"related":%"U%+([^%"]+)%"');
   if (c) then
      c = tonumber(c, 16);
      if (true or c < 0x10000) then
         c = utf8.char(c);
      else
--         c = c - 0x10000;
--         c = utf8.char((0xD800 | (c >> 10)), (0xDC00 | (c & 0x3FF)));
      end
   end
   return m, c;
end

--[[
local getjson = function(page)
   local ret = execcmd("grep '^ " .. page .. " ' ../gwdiff/cgi/gw1205/dump_newest_only.txt  -r");
   local data = ret:split("|");
   if (#data < 3) then return nil, nil end

   local m = data[3]:trim();
   local c = data[2]:trim();

   if (c) then
      c = ucs2c(c);
   end

   --print ("current = ",m,c);
   return m,c;
end
]]
local accesswiki = function(page, glyph, c, overwrite)
   if (false) then
      local fp = io.open("reglog/"..page..".dat","r")
      if (fp) then
         fp:close();
         return
      end
   end

   print("#####success", page, c, glyph, overwrite);

   if (arg[1] ~= "exist" and arg[1] ~= "register") then
      return
   end


   -- 入れ替えの場合
   if (overwrite == "swap") then
      local cmd = "curl -w '\\n'"
      cmd = cmd .. (" 'http://glyphwiki.org/wiki/%s?action=swap'"):format(page);
      cmd = cmd .. " -b gwcookie.txt"
      print(cmd);

      if (arg[1] == "register") then
         execcmd(cmd);
         --execcmd("sleep 1");
      end
      return;
   end

   
   -- check if there's registered glyph
   local data,c0 = getjson(page);

   -- 関連字だけ差し替える場合
   if (overwrite == "refch") then
      glyph = data   

   -- 現在最新が実体である場合
   elseif (data and not data:match("^99:0:0:0:0:200:200:([^:]+)$")) then

      -- 自分を参照しているやつらを拾い出す
      local ret = execcmd("grep '99:0:0:0:0:200:200:" .. page .. "$' ../gwdiff/cgi/gw1205/dump_newest_only.txt  -r");
      local k = ret:split("\n");

      -- 上書きの場合(参照がいれば上書きしない:要swap)
      if (overwrite == "overwrite") then
         if (0 < #k) then
            -- todo: swap
            local cmd = "echo " .. page .. " as otheralias >> ./reglog/undone ";
            execcmd(cmd);
            return
      -- 両保持の場合(参照がいればvarを検索)
      elseif (overwrite == "branch")  then
         local ret = execcmd("grep '99:0:0:0:0:200:200:" .. page .. "$' ../gwdiff/cgi/gw1205 -r");
         if (#k == 0) then
            -- todo: "u%x-var-%d":format(c, i) の作成
            local ret = execcmd("grep '^ " .. ("u%x-var-"):format(utf8.codepoint(c)) .. "' ../gwdiff/cgi/gw1205/dump_newest_only.txt  -r");
            local n = ret:split("\n");

            local cmd = "echo '" .. page .. " as nobranch ";
            cmd = cmd .. ("(u%x-var-%03d)"):format(utf8.codepoint(c), #n + 1);
            cmd = cmd .. "' >> ./reglog/branch ";
            execcmd(cmd);
            return;

         end
         local page = k[1]:split(" ");
         execcmd("echo 'https://glyphwiki.org/wiki/".. page[1] .."?action=swap' >> ./reglog/swaps");

         return;
      else
         local cmd = "echo " .. page .. " as original >> ./reglog/undone ";
         execcmd(cmd);
         return
      end
   end


   local timestump = os.time();

   local cmd = "curl -w '\\n'"
   cmd = cmd .. (" 'http://glyphwiki.org/wiki/%s'"):format(page);
   cmd = cmd .. (" -d 'page=%s' "):format(page);
   cmd = cmd .. (" -d 'edittime=%d' "):format(timestump);
   cmd = cmd .. (" -d 'textbox=%s'"):format(glyph);
   if (c)  then cmd = cmd .. (" -d 'related=%s'"):format(c); end
   --cmd = cmd .. (" --data-urlencode 'summary=関連字'");
   cmd = cmd .. (" --data-urlencode 'buttons=以上の記述を完全に理解し同意したうえで投稿する'");
   cmd = cmd .. " -b gwcookie.txt"
   cmd = cmd .. (" >> ./reglog/%s.dat"):format(page);

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

local ucs2c = function(ucs)
   --print("??",ucs);
   local hex = ucs:match("u(%x+)");
   if (not hex) then return ucs; end
   return utf8.char(tonumber("0x"..hex));
end

--版4: reg.datのとおりに登録する
local pickups = function(buff)
   line = buff:split("\t");
   if (#line < 2) then  return; end
   local dkws = line[1]:split("[");
   local dkw = dkws[1];
   local c = (dkws[2] or "〓"):split("]")[1] or "〓";
   local glyph = line[2];
   local cat = line[3];
   local ow = line[4] or ""
   
   if (dkw:match("^dkw%-")==nil and dkw:match("^u%x") == nil 
          and dkw:match("^nyukan%-")==nil and dkw:match("^toki%-") == nil
          and dkw:match("^gt%-")==nil and dkw:match("^jmj%-") == nil
   ) then
      print("##format");
      return
   end
   if (not glyph) then
      print("##no glyph");
      return
   end
   if (c:match("^u%x+")) then
      local ucs = "0x" .. c:match("^u(%x+)");
      c = utf8.char(tonumber(ucs));
   end
   glyph = table.join(glyph:split("$"), "$");
   if (glyph:sub(1,2) == "[[") then
      c = "〓"
   end

   if (cat:match("^#[hr%-]") or glyph == "_" or glyph == "[[]]") then
      local cmd = "echo " .. dkw .. " as undef >> ./reglog/undone ";
      execcmd(cmd);
      return
   end
   accesswiki(dkw, glyph, c, ow);

end

--版4: reg.datのとおりに登録する
local crawl_table = function(e0, e1)
   local fp = io.open("reg0107.dat","r")
   --local fp = io.open("reglog/swaps","r")
   local i = 0;
   for line in fp:lines() do
      i = i + 1;
      if (e0 <= i) then pickups(line) end
      if (e1 <= i) then break end
   end
   fp:close();
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

execcmd("mkdir -p ./reglog");

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



