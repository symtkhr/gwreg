require "stringadd"

local execcmd = function(command, is_shown)
   if (is_shown) then print(command); end
   if (true) then
      local handle = io.popen(command, "r")
      local content = handle:read("*all")
      handle:close()
      return content
   end
   return '{"data":"99:0:0:0:0:200:200:u4e00-j", "related": "〓"}';
end

local help = function()
   print (" # " .. arg[0] .. " [mode] [start] [end]");
   print ("");
   print (" [mode] ");
   print ("  - dump: Only dump");
   print ();
   print (" [start][end]");
   print ("  - mj1_ishii.txt entry");
   print ("  (replace parts from using p.original.dat)");
   print ();
end


--[[ 
<<変換テーブルの縮尺変更>>
 adj=30〜100の場合、
   0   30        100                200
   +----+----------+-----------------+
   20   p          q                70
   p = 20 + (50 * 30/200) = 27.5, q = 20 + (50 * 100/200) = 45
   p = x0 + (x1-x0) * X0/200, q = x0 + (x1-x0) * X1/200
]]



local getjson = function(page)
   local cmd = "curl -w '%{http_code}' http://glyphwiki.org/json?name=" .. page;
   cmd = cmd .. " -s -S"
   --print(cmd);
   local ret = execcmd(cmd, true);
   local m = ret:match('"data":%"([^%"]+)%"');
   local c = ret:match('"related":%"U%+([^%"]+)%"');
   if (c) then
      print(c);
      c = tonumber(c, 16);
      if (true or c < 0x10000) then
         c = utf8.char(c);
      else
         c = c - 0x10000;
         c = utf8.char((0xD800 | (c >> 10)), (0xDC00 | (c & 0x3FF)));
      end
   end
   return m, c;
end

local incl2array = function(incl)
   if (incl == nil) then return {}; end
   local m = ("*" .. incl:trim()):split("/");

   incl = m[2] or "";
   local ret = {};

   for p, c in utf8.codes(incl) do
      if (utf8.char(c) == "真") then c = utf8.codepoint("眞"); end
      if (utf8.char(c) == "曰") then c = utf8.codepoint("日"); end
      if (0x80 <= c) then
         ret[#ret + 1] = ("u%x"):format(c);
      end
   end
   return ret;
end

local undones;
local dones;
--完了判定
local undone = function(dkw)
   if (undones ~= nil) then
      return undones[dkw];
   end

   undones = {};
   local done = {};
   local fp = io.open("done/donelist.dat","r")
   local iter = function(line)
      local m = line:match("(dkw%-[0-9dh]+)%.dat");
      if (not m) then return end
      local ls = line:split("\t");
      if (not ls[6]) then return m, "mtnest" end
      if (ls[6] == "as-0") then return m, "koseki(m)" end
      if (ls[6]:match("^as%-%d")) then return m, "original(m)" end
      return m, "mtnest"
   end
   for line in fp:lines() do
      local m, v = iter(line);
      if (m) then
         done[m] = v;
      end
   end
   fp:close();

   dones = done;
   return undones[dkw];
end

--ucsからdkwを得る
local uk2d;
local d2uk;
local ucs2dkw = function(key)
   if (uk2d ~= nil) then
      return uk2d[key];
   end
   uk2d = {};
   d2uk = {};
   local fp = io.open("mji_00502_pickup.txt","r")
   for gline in fp:lines() do
      local line = gline:split("\t");
      local dkw = line[1];
      local koseki = line[2];
      local ucs = line[3]:lower():gsub("^u%+", "u");
      local ivs0 = (line[4] or ""):lower();
      local ivs = (ivs0:match("^%x+_%x+$")) and "u" .. ivs0:gsub("_", "-u") or ucs;
      local page = (function(dkw)
        local page = dkw:trim():gsub("補", "h"):gsub("%'", "d");
        local n = page:match("%d+")
        return page:gsub(n, (page:find("%-h") and "%04d" or "%05d"):format(n));
      end)(dkw);

      local alias = (function(koseki)
         local glyph = koseki:match("^ksk%-(%d+)$");
         return glyph and ("koseki-%s"):format(glyph) or nil;
      end)(koseki);
      uk2d[ucs] = uk2d[ucs] and uk2d[ucs] .. "," .. page or page;
      -- print("uk2d", ucs, uk2d[ucs]);
      if (alias) then
         uk2d[alias] = page;
         d2uk[page] = {koseki=alias, c=ivs};
      else
         d2uk[page] = {koseki="jmj",c=ivs};
      end
   end
   fp:close();
   return uk2d[key];
end

local ucs2c = function(ucs)
   --print("??",ucs);
   local hex = ucs:match("u(%x+)");
   if (not hex) then return "〓"; end
   return utf8.char(tonumber("0x"..hex));
end

-- 行内からpcode関連のものを探して可能なら差し替える
local find_and_replace = function(gline, pcode)
   -- エイリアスか?
   if (gline:match("^99:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:") == nil) then
      return false, gline;
   end
   
   local lined = gline:split(":")
   --local part = utf8.char(pcode);

   local alias = lined[8]:split("@")[1];
   --print(alias, "vs", pcode)
   -- エイリアスがpcodeで始まるか?
   if (alias:sub(1,pcode:len()) ~= pcode) then return false, gline; end
   --print("true")
   -- 定義済のものはテーブルの値に差し替え
   for _, refglyph in ipairs(reptable) do
      if ((refglyph[1] == alias) or (refglyph[1].."-j" == alias) or (refglyph[1].."-jv" == alias)) then
         lined[8] = refglyph[2];
         if (refglyph.x) then
            local x0 = lined[4];
            local x1 = lined[6];
            lined[4] = math.floor(x0 + (x1 - x0) * refglyph.x[1] / 200)
            lined[6] = math.floor(x0 + (x1 - x0) * refglyph.x[2] / 200)
         end
         if (refglyph.y) then
            local y0 = lined[5];
            local y1 = lined[7];
            lined[5] = math.floor(y0 + (y1 - y0) * refglyph.y[1] / 200)
            lined[7] = math.floor(y0 + (y1 - y0) * refglyph.y[2] / 200)
         end
         --done[#done + 1] = part;
         return refglyph[2], table.join(lined, ":");
      end
   end
   -- 処置不要なものは処置しない
   for _, p in ipairs(unhandled) do
      if (alias == p) then
         return p, table.join(lined, ":");
      end
   end
   --[[
   {"aj1-13642", "aj1-13774", "aj1-13797","aj1-13817","aj1-13939","aj1-13945","aj1-13976","aj1-13993","aj1-14057","aj1-14112"}
   "遺購資習通的博鼻盲曼"
   ]]
   -- 定義がない"uXXXX"/"koseki-XXXX"は dkw-XXXXXに直差し替え
   local refg = pcode:match("^(u%x+)") or pcode:match("^(koseki%-[0-9]+)$") or "";
   local dkw = uk2d[refg];
   if (dkw and dkw:find("dkw%-h")) then dkw = nil; end
   local is_simple = ((refg == alias) or (refg.."-j" == alias) or (refg.."-jv" == alias));
   if (dkw and is_simple) then
      lined[8] = dkw;
      return dkw, table.join(lined, ":"), (undone(dkw) and ("unreg:" .. dkw .."(" .. ucs2c(refg) .. ")"));
   end
   -- 対応するdkwがない
   if (not dkw and is_simple) then
      return "nodkw", gline, ("nodkw:" .. pcode .. "("..ucs2c(refg) ..")");
   end
   -- alias に "-01"とか"-ue0xxxx"とか"-itaiji-xxx"とかついちゃってる模様
   return "undef", gline, ("undef:" .. lined[8] .. "(" .. ucs2c(refg)  .. ":" .. (dkw or "") .. ")");
end

local originglyph = (function()
   local fp = io.open("p.original.dat","r")
   local p = {};
   for line in fp:lines() do
      local data = line:split(" ");
      local dkw = data[1];
      local c = data[2];
      local origin = data[3];
      if (dkw) then p[dkw] = origin; --print(dkw, origin);
      end
   end
   fp:close();

   return p;
end)()

local get_glyph = function(koseki, page)
   --glyphwikiから直接取得する場合はfalse, p.original.datから得る場合はtrue
   if (false) then
      local cmd = ("awk '$1 == \"%s\"{print $3,$2}' p.original.dat"):format(page);
      local ret = execcmd(cmd);
      --print("?", ret);
      if (ret ~= "") then
         local tmp = ret:split(" ");
         return tmp[1], tmp[2]:trim();
      end
   end
   
   local data,c = getjson(koseki);
   -- 実体でなければ実体にアクセス
   local m = data:match("^99:0:0:0:0:200:200:([^:]+)$");
   if (m) then
      data,c = getjson(m);
   end
   return data, c;
end

if(false) then
   local row = {"u610f-08"};
   local data,c = get_glyph(row[1]);
   local cmd = ("echo '%s %s %s' >> p.origina2.dat"):format(row[1], c, data);
   execcmd(cmd);
end

if (false) then
   --グリフ定義を持ってくる
   local fp = io.open("p.getdef.dat", "r");
   for line in fp:lines() do
      local row = line:split(" ");
      local data,c = get_glyph(row[2]);
      local cmd = ("echo '%s %s %s' >> p.origina2.dat"):format(row[1], c, data);
      execcmd(cmd);
   end
   fp:close();
end

local dump_pdat = function(dkw, koseki, ucs, glyph, cat, pstr)
   execcmd(("echo '%s %s %s:%s %s %s %s' >> p.dat"):format(dkw, koseki, ucs, ucs2c(ucs), glyph, cat, pstr, replaced));
end

local replace_parts = function(koseki, parts, page, c)
   --glyphデータと関連字を得る
   -- local data,c = get_glyph(koseki, page);

   local data = originglyph[page];
   --print(data);
   if (data == nil) then data = "" end
   if (c == nil) then c = "" end
   local ms = data:split("$");
   local done = {};
   local undef = {};

   local pstr = "";
   for _, p in ipairs(parts) do pstr = pstr.. (("%s[%s]"):format( p:match("^u") and ucs2c(p) or "〓", p)); end
   --print(" searching... " .. pstr);
   
   -- 目的の部品があるか探す
   for i, pcode in ipairs(parts) do
      -- 1行ずつ見る
      for _, line in ipairs(ms) do
         local ret, und;
         ret, line, und = find_and_replace(line, pcode);

         -- 見つかった
         if (ret) then
            --print("* ", ms[_], "=>", line);
            ms[_] = line;

            done[#done + 1] = pcode .. "=" .. ret;
            -- 見つかったが部品用のサイズ定義がない
            if (und) then undef[#undef + 1] = und; end
            break;
         end
      end
      if (i ~= #done or #undef ~= 0) then break end
   end

   --変換結果をp.datに保存する

   -- 見つかったが定義がない
   if (#undef ~= 0) then
      --print("#### undef error: " .. table.join(undef, ";"));
      dump_pdat(page, koseki, c, data, "##"..table.join(undef, ","), pstr);
      return
   end
   -- 見つからないものがある
   if (#done ~= #parts) then
      --print("#### notfound error: ",  table.join(ms, "$"))
      
      dump_pdat(page, koseki, c, data, "##noparts:", pstr);
      return;
   end

   -- 処置不要
   if (table.join(ms, "$") == data) then
      return dump_pdat(page, koseki, c, "[[" .. koseki .. "]]", "##unhandled", pstr);
   end

   return dump_pdat(page, koseki, c, table.join(ms, "$"), "##success:"..table.join(done, ";"), pstr); 
end


-- 版4:mj1_ishii.txtを読んで指定パーツを差し替える
local pickups = function(buff)
   line = buff:split("\t");
   local dkw = line[1];
   local koseki = line[2];
   local incl = line[4];

   print();
   print(dkw, line[3]);
   --ひとまず完了したものは手をつけない
   if (undone(dkw) ~= true) then print("done"); return; end
   --kosekiと紐付いているものが対象
   if (koseki:match("^koseki%-") == nil) then print("## no-koseki"); return end;

   -- partsはp.noparty.datに定義されていればそちらを優先する
   local ret = execcmd(("grep '%s[^d]' p.noparty.dat"):format(dkw))
   local parts = {}
   if (ret == "") then
      parts = incl2array(incl);
   else
      local glyph = ret:split("\t")[4];
      local m = glyph:match("^<([^>]+)>");
      if (m) then
         if (m:match("^[amr]")) then print("man"); return; end
         parts = incl2array(m);
      else
         for _, d in ipairs(ret:split("\t")[4]:split(",")) do
            local m = d:match("^q.+%[(.+)%]")
            if (m) then parts[#parts  + 1] = m:split("@")[1]; end
         end
      end
   end
   if (parts == nil or #parts == 0) then print("noparts"); return; end

   return replace_parts(koseki, parts, dkw);
end

-- 版4:mj1_ishii.txtを読んで指定パーツを差し替える
local crawl_table = function(e0, e1)
   local fp = io.open("mj1_ishii.txt","r")
   local i = 0;
   for line in fp:lines() do
      i = i + 1;
      if (e0 <= i) then pickups(line) end
      if (e1 <= i) then break end
   end
   fp:close();
end

local dashlist = {
"dkw-00366d","dkw-00462d","dkw-00628d","dkw-00629d","dkw-00927d","dkw-01042d","dkw-01368d","dkw-02076d","dkw-02076dd","dkw-02112d",
"dkw-02360d","dkw-02384d","dkw-02415d","dkw-02506d","dkw-02761d","dkw-03048d","dkw-03118d","dkw-03365d","dkw-03372d","dkw-03381d",
"dkw-03441d","dkw-03709d","dkw-03987d","dkw-04138d","dkw-04349d","dkw-04624d","dkw-04641d","dkw-04703d","dkw-04734d","dkw-04772d",
"dkw-04815d","dkw-04829d","dkw-04836d","dkw-04841d","dkw-04866d","dkw-04879d","dkw-05086d","dkw-05316d","dkw-05317d","dkw-05448d",
"dkw-05541d","dkw-05571d","dkw-05647d","dkw-05700d","dkw-05801d","dkw-05990d","dkw-06307d","dkw-06432d","dkw-06807d","dkw-07278d",
"dkw-07296d","dkw-07419d","dkw-07437d","dkw-07463d","dkw-07493d","dkw-07550d","dkw-07806d","dkw-08068d","dkw-08212d","dkw-08624d",
"dkw-08680d","dkw-08696d","dkw-08759d","dkw-09224d","dkw-09392d","dkw-09791d","dkw-09836d","dkw-09909d","dkw-09995d","dkw-10080d",
"dkw-10237d","dkw-10238d","dkw-10312d","dkw-10347d","dkw-10617d","dkw-10618d","dkw-10629d","dkw-10716d","dkw-10756d","dkw-10905d",
"dkw-10980d","dkw-11024d","dkw-11188d","dkw-11269d","dkw-11398d","dkw-11399d","dkw-11400d","dkw-11542d","dkw-11606d","dkw-11631d",
"dkw-11743d","dkw-11901d","dkw-11902d","dkw-11917d","dkw-11969d","dkw-11985d","dkw-12081d","dkw-12179d","dkw-12191d","dkw-12237d",
"dkw-12311d","dkw-12346d","dkw-12445d","dkw-12557d","dkw-12613d","dkw-12674d","dkw-12845d","dkw-12975d","dkw-13202d","dkw-13239d",
"dkw-13285d","dkw-13359d","dkw-13553d","dkw-13936d","dkw-13994d","dkw-14030d","dkw-14031d","dkw-14111d","dkw-14227d","dkw-14340d",
"dkw-14345d","dkw-14362d","dkw-14368d","dkw-14374d","dkw-14488d","dkw-14577d","dkw-14687d","dkw-14795d","dkw-14796d","dkw-15065d",
"dkw-15217d","dkw-15352d","dkw-15364d","dkw-15484d","dkw-15485d","dkw-15880d","dkw-15992d","dkw-16024d","dkw-16283d","dkw-16326d",
"dkw-16334d","dkw-16582d","dkw-16618d","dkw-16709d","dkw-16724d","dkw-17046d","dkw-17072d","dkw-17479d","dkw-17505d","dkw-17529d",
"dkw-17572d","dkw-17573d","dkw-17695d","dkw-17749d","dkw-17750d","dkw-17783d","dkw-17919d","dkw-17920d","dkw-17921d","dkw-18067d",
"dkw-18068d","dkw-18277d","dkw-18672d","dkw-18953d","dkw-18981d","dkw-19165d","dkw-19166d","dkw-19371d","dkw-19372d","dkw-19561d",
"dkw-19562d","dkw-19596d","dkw-19630d","dkw-19705d","dkw-19710d","dkw-20137d","dkw-20190d","dkw-20406d","dkw-20511d","dkw-20512d",
"dkw-20714d","dkw-20777d","dkw-20786d","dkw-20817d","dkw-21223d","dkw-21334d","dkw-21419d","dkw-21420d","dkw-21607d","dkw-21684d",
"dkw-21739d","dkw-21805d","dkw-21875d","dkw-22662d","dkw-22972d","dkw-23001d","dkw-23210d","dkw-23275d","dkw-23668d","dkw-24080d",
"dkw-24120d","dkw-24201d","dkw-24364d","dkw-24449d","dkw-24626d","dkw-24631d","dkw-24640d","dkw-24641d","dkw-24652d","dkw-24664d",
"dkw-24672d","dkw-24673d","dkw-24689d","dkw-24741d","dkw-24766d","dkw-24767d","dkw-24768d","dkw-24787d","dkw-24873d","dkw-25016d",
"dkw-25070d","dkw-25081d","dkw-25187d","dkw-25188d","dkw-25236d","dkw-25280d","dkw-25334d","dkw-25335d","dkw-25547d","dkw-25703d",
"dkw-25814d","dkw-25815d","dkw-25838d","dkw-26027d","dkw-26028d","dkw-26297d","dkw-26494d","dkw-26520d","dkw-26623d","dkw-26647d",
"dkw-26726d","dkw-26727d","dkw-26997d","dkw-27118d","dkw-27147d","dkw-27258d","dkw-27327d","dkw-27464d","dkw-27541d","dkw-27631d",
"dkw-27632d","dkw-27656d","dkw-27731d","dkw-27803d","dkw-27804d","dkw-27805d","dkw-28065d","dkw-28080d","dkw-28311d","dkw-28614d",
"dkw-28635d","dkw-28657d","dkw-28672d","dkw-28801d","dkw-28838d","dkw-28907d","dkw-28909d","dkw-29074d","dkw-29223d","dkw-29263d",
"dkw-29396d","dkw-29421d","dkw-29422d","dkw-29539d","dkw-29567d","dkw-29745d","dkw-29807d","dkw-29808d","dkw-29965d","dkw-29966d",
"dkw-29995d","dkw-30103d","dkw-30192d","dkw-30260d","dkw-30278d","dkw-30323d","dkw-30342d","dkw-30670d","dkw-30699d","dkw-30734d",
"dkw-30736d","dkw-30741d","dkw-30781d","dkw-30796d","dkw-30797d","dkw-30808d","dkw-30833d","dkw-30860d","dkw-30861d","dkw-30915d",
"dkw-30945d","dkw-30953d","dkw-31000d","dkw-31131d","dkw-31133d","dkw-31153d","dkw-31156d","dkw-31168d","dkw-31184d","dkw-31329d",
"dkw-31330d","dkw-31362d","dkw-31387d","dkw-31448d","dkw-31618d","dkw-31642d","dkw-31828d","dkw-31883d","dkw-31884d","dkw-31885d",
"dkw-32048d","dkw-32083d","dkw-32143d","dkw-32149d","dkw-32188d","dkw-32189d","dkw-32294d","dkw-32340d","dkw-32346d","dkw-32477d",
"dkw-32477dd","dkw-32678d","dkw-32720d","dkw-32723d","dkw-32784d","dkw-33775d","dkw-33907d","dkw-33908d","dkw-33931d","dkw-33999d",
"dkw-34046d","dkw-34065d","dkw-34163d","dkw-34283d","dkw-34413d","dkw-34470d","dkw-34631d","dkw-34737d","dkw-34768d","dkw-34789d",
"dkw-34827d","dkw-35135d","dkw-35218d","dkw-35324d","dkw-35497d","dkw-35502d","dkw-35546d","dkw-35556d","dkw-35580d","dkw-35609d",
"dkw-35640d","dkw-35690d","dkw-35691d","dkw-35692d","dkw-35727d","dkw-35778d","dkw-35779d","dkw-35780d","dkw-35821d","dkw-35850d",
"dkw-35931d","dkw-35991d","dkw-36037d","dkw-36038d","dkw-36168d","dkw-36486d","dkw-36628d","dkw-36802d","dkw-36803d","dkw-36920d",
"dkw-37034d","dkw-37519d","dkw-37547d","dkw-37955d","dkw-38234d","dkw-38438d","dkw-38482d","dkw-38613d","dkw-38630d","dkw-38710d",
"dkw-38712d","dkw-38727d","dkw-38748d","dkw-38752d","dkw-38758d","dkw-38797d","dkw-38800d","dkw-38803d","dkw-38825d","dkw-38836d",
"dkw-38839d","dkw-38842d","dkw-38845d","dkw-38849d","dkw-38876d","dkw-38877d","dkw-38881d","dkw-38882d","dkw-38892d","dkw-38897d",
"dkw-38898d","dkw-38902d","dkw-38931d","dkw-38937d","dkw-38943d","dkw-38951d","dkw-38956d","dkw-38985d","dkw-38989d","dkw-38991d",
"dkw-38994d","dkw-38998d","dkw-39001d","dkw-39002d","dkw-39010d","dkw-39011d","dkw-39047d","dkw-39052d","dkw-39067d","dkw-39076d",
"dkw-39082d","dkw-39112d","dkw-39118d","dkw-39123d","dkw-39127d","dkw-39134d","dkw-39163d","dkw-39174d","dkw-39190d","dkw-39357d",
"dkw-39405d","dkw-39497d","dkw-39498d","dkw-39542d","dkw-39870d","dkw-40064d","dkw-40120d","dkw-40132d","dkw-40145d","dkw-40340d",
"dkw-40418d","dkw-40503d","dkw-40519d","dkw-40596d","dkw-40708d","dkw-41260d","dkw-41341d","dkw-41676d","dkw-41720d","dkw-41721d",
"dkw-41764d","dkw-41836d","dkw-41858d","dkw-41860d","dkw-42128d","dkw-42216d","dkw-42309d","dkw-42343d","dkw-42417d","dkw-42564d",
"dkw-42570d","dkw-42574d","dkw-43256d","dkw-43256dd","dkw-43318d","dkw-43529d","dkw-43591d","dkw-43608d","dkw-43609d","dkw-43689d",
"dkw-43920d","dkw-44023d","dkw-44037d","dkw-44063d","dkw-44064d","dkw-44107d","dkw-44109d","dkw-44111d","dkw-44168d","dkw-44237d",
"dkw-44459d","dkw-44500d","dkw-44633d","dkw-44695d","dkw-44833d","dkw-44834d","dkw-44915d","dkw-45013d","dkw-45043d","dkw-45089d",
"dkw-45240d","dkw-45387d","dkw-45649d","dkw-45906d","dkw-46226d","dkw-46525d","dkw-47074d","dkw-47446d","dkw-47909d","dkw-47926d",
"dkw-48063d","dkw-48300d","dkw-48498d","dkw-48632d","dkw-49626d","dkw-49757d",
};
-- 版5:undoneなものをすべて検証する
local crawl_table = function(e0, e1)

   local incls = {};
   local dkwdef = (function()
      local ret = {};
      local fp = io.open("dkwdef.txt","r")
      for line in fp:lines() do
         local data = line:split(" ");
         local dkw = data[1];
         local glyph = data[2];
         ret[dkw] = glyph;
      end
      fp:close();
      return ret;
   end)();
   
   local kskdef = (function()
      local ret = {};
      local fp = io.open("kosekidef.txt","r")
      for line in fp:lines() do
         local data = line:split(" ");
         local dkw = data[1];
         local glyph = data[2];
         ret[dkw] = glyph;
      end
      local fp = io.open("kosekidef+.txt","r")
      for line in fp:lines() do
         local data = line:split(" ");
         local dkw = data[1];
         local glyph = data[2];
         ret[dkw] = glyph;
      end
      fp:close();
      return ret;
   end)();

   local readnoparty = function(line)
      local parts = {}
      local dkw = line:split("\t")[1];
      local glyph = line:split("\t")[4];
      if (not dkw or dkw:match("^dkw%-") == nil or glyph == nil) then return end
      local m = glyph:match("^<([^>]+)>");
      if (m) then
         if (m:match("^a")) then return dkw, {m}  end
         if (m:match("^r")) then return dkw, {m}  end
         if (m:match("^m")) then return dkw, {"m"}  end
         return dkw, incl2array("/" ..m);
      end
      for _, d in ipairs(glyph:split(",")) do
         local m = d:match("^q.+%[(.+)%]")
         if (m) then parts[#parts  + 1] = m:split("@")[1];  end
      end
      if (parts == nil or #parts == 0) then return nil; end
      return dkw, parts;
   end

   local read_ishii = function(buff)
      local line = buff:split("\t");
      local dkw = line[1];
      local koseki = line[2];
      local incl = line[4];
      if (incl == "") then return end
      return dkw, incl2array(incl);
   end

   local partsmake = function(dkw)
      local fp = io.open("mj1_ishii.txt","r")
      for line in fp:lines() do
         local dkw, ps = read_ishii(line);
         --print(dkw, table.join(ps, ","));
         if (dkw) then incls[dkw] = ps; end
      end
      fp:close();
      local fp = io.open("p.noparty.dat","r")
      for line in fp:lines() do
         local dkw, ps = readnoparty(line);
         --print(dkw, ps and table.join(ps, ","));
         if (dkw) then incls[dkw] = ps; end
      end
      fp:close();
      --Todo:ここにread_undefparty()とか
   end

   local kdbonly = (function()
      local p = {};
      local fp = io.open("kdbonly.txt","r")
      for line in fp:lines() do
         local data = line:trim():split(",");
         local c = data[1];
         local dkw = data[2];
         if (dkw) then
            local page = "dkw-" ..(function(dkw)
               local page = dkw:trim():gsub("補", "h"):gsub("%'", "d");
               local n = page:match("%d+")
               return page:gsub(n, (page:find("^h") and "%04d" or "%05d"):format(n));
            end)(dkw);
            p[page] = ("u%x"):format(utf8.codepoint(c));
            --print(page, p[page], c);
         end
      end
      return p;
   end)()
   
   local pickups = function(dkw)
      local koseki = (d2uk[dkw]) and d2uk[dkw].koseki;
      if (not koseki) then
         return;
      end
      local ucs = (d2uk[dkw]) and d2uk[dkw].c;
      local pstr = "";
      local target = incls[dkw];

      --for _, p in ipairs(target) do
      --pstr = pstr.. (("%s[%s]"):format( p:match("^u") and ucs2c(p) or "〓", p));
      --end

      if (undones[dkw] or dones[dkw]) then
         --dumppdat(dkw, koseki, c, "_", "##done:mtnest", pstr);
         return;
      end
      local data = dkwdef[dkw];
      local m = data:match("^99:0:0:0:0:200:200:([^:]+)$");
      if (m) then
         return
      end
      data,c = getjson(koseki);
      execcmd(("echo '%s %s %s %s' >> kosekidef+.txt"):format(koseki, data, c, dkw), true);
      if (false) then
         if (m and not m:match("koseki")) then
            data,c = getjson(koseki);
         end
         execcmd(("echo '%s %s %s %s' >> kosekidef.txt"):format(koseki, data, c, dkw), true);
      end
   end

   -- 定義を拾ってくる
   local looptable = function()
      local i = 0;
      for i = 1, 49964 do
         local dkw = ("dkw-%05d"):format(i);
         pickups(dkw);
         --if (i % 1000 == 0) then execcmd("sleep 10"); end
      end
      for i, dkw in ipairs(dashlist) do
         pickups(dkw);
         if (i % 1000 == 0) then execcmd("sleep 10"); end
      end

      for i = 1, 804 do
         local dkw = ("dkw-h%04d"):format(i);
         pickups(dkw);
         if (i % 1000 == 0) then execcmd("sleep 10"); end
      end
   end

   local looptable = function()
      for i = 1, 804 do
         local dkw = ("dkw-h%04d"):format(i);
         local c = (d2uk[dkw]) and d2uk[dkw].c or kdbonly[dkw];
         if (c) then 
            print(('%s %s %s [[%s]]'):format(dkw, "_", ucs2c(c), c));
         end
      end
   end

   local pickups = function(dkw)
      local koseki = (d2uk[dkw]) and d2uk[dkw].koseki or "none";
      local ucs = (d2uk[dkw]) and d2uk[dkw].c or kdbonly[dkw];
      local pstr = "";
      local target = incls[dkw];


      local makecat = function(dkw)
         if (dones[dkw]) then
            return dones[dkw];
         end
         if (not dkwdef[dkw] or dkwdef[dkw] == "nil") then
            return "undone";
         end

         local dkwdef0 = dkwdef[dkw];
         local dkw0 = dkwdef0:match("^99:0:0:0:0:200:200:([^:]+)$") or "";
         local kskdef0 = kskdef[koseki] or "";
         local ksk0 = kskdef0:match("^99:0:0:0:0:200:200:([^:]+)$") or "";

         if (dkw0 == "") then
            return (ksk0 ~= "" and ksk0 == dkw) and "koseki" or "original";
         end
         if (dkw0 == koseki or dkw0 == ksk0) then
            return "koseki";
         end
         return "alias:" .. dkw0;
      end
      local cat = makecat(dkw);
      if (cat == "undone") then return end
      local pstr = "";
      for _, p in ipairs(incls[dkw] or {}) do
         pstr = pstr.. (("%s[%s]"):format( p:match("^u") and ucs2c(p) or "〓", p));
      end

      print(('%s %s %s _ ##done:%s %s'):format(dkw, koseki, ucs, cat, pstr));
      --execcmd(("echo '%s %s %s ##done:%s' >> p.done.dat"):format(dkw, koseki, ucs, cat), true);

   end
   -- p.cat.datをつくる
   local looptable = function()
      local i = 0;
      for i = 1, 49964 do
         local dkw = ("dkw-%05d"):format(i);
         pickups(dkw);
      end
      for i, dkw in ipairs(dashlist) do
         pickups(dkw);
      end

      for i = 1, 804 do
         local dkw = ("dkw-h%04d"):format(i);
         pickups(dkw);
      end
   end

   
   -- addlistテーブルの文字をreplace
   local looptable0 = function()
      --[[local addlist = {"dkw-14643","dkw-00482","dkw-00724","dkw-39939","dkw-23462","dkw-14285","dkw-23548","dkw-30120"};
      for _, u in ipairs({"冒","淂","厝","奠","嚴","叢","借","乾","俎","問","凌","伯","奭","淩","開","匍","匱","寔","𡚐"}) do
      --]]
      local addlist = {};
      for _, u in ipairs({"鼻"}) do
         local ucs = ("u%x"):format(utf8.codepoint(u));
         addlist[#addlist + 1] = uk2d[ucs]:split(",")[1];
         print(ucs, uk2d[ucs]:split(",")[1]);
      end

      for _, dkw in ipairs(addlist) do
         pickups(dkw)
      end
   end

   undone("dummy");  -- undones作成
   ucs2dkw("dummy"); -- d2uk,uk2d作成
   partsmake();      -- incls作成

   looptable();
end


if (#arg ~= 3) then
   help();
   return;
end

local e0 = tonumber(arg[2]);
local e1 = tonumber(arg[3]);
if (e0 > e1) then
   help();
   return;
end
crawl_table(e0, e1);






