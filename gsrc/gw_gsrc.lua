
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
   if (not hex) then return ucs; end
   return utf8.char(tonumber("0x"..hex));
end

--dump undone
local usrc = arg[1];
local gwsrc = arg[2];
local cmd = ("grep kIRG_GSource %s | cut -f1"):format(usrc);
local ret = execcmd(cmd);
local ud = {};

for k in ret:split_it("\n") do
    local c = k:match('^U%+(%x+)$');
    if (c) then
       ud[tonumber("0x" .. c)] = 'd';  -- undone
    end
end

-- 作成済gsrc 
local cmd = ("grep -E '^ u[0-9a-f]+-g ' %s"):format(gwsrc);
local ret = execcmd(cmd);

for k in ret:split_it("\n") do
    local s = k:split("|")
    local c = s[1]:match('u(%x+)');
    if (c) then
       -- gSrcがjまたは無印エイリアス
       local grp = s[3]:match("^ +99:0:0:0:0:200:200:u([^:]+)$");
       if (grp == (c .. "-j") or grp == (c .. "-jv") or grp == c)
       then
          ud[tonumber("0x" .. c)] = 'h';  -- unhandled
       else
          ud[tonumber("0x" .. c)] = 't';  -- target
       end
    end
end

--jまたは無印がgSrcエイリアス
local cmd = ("grep -E ' 99:0:0:0:0:200:200:u([0-9a-f]+)-g$' %s"):format(gwsrc);
local ret = execcmd(cmd);

for k in ret:split_it("\n") do
    local s = k:split("|")
    local grp = s[1]:match(' u([^ ]+) ');
    if (grp) then
        local c = s[3]:match("^ +99:0:0:0:0:200:200:u([^:]+)%-g$");
        if (grp == (c .. "-j") or grp == (c .. "-jv") or grp == c)
        then
            ud[tonumber("0x" .. c)] = 'h';
        end
     end
end



for i = 0x3400, 0x9fff do
    --local c = ("%x"):format(i);
    if (ud[i]) then
        print(("%x"):format(i), utf8.char(i), ud[i]);
    end
end
for i = 0x20000, 0x2ebdf do
    --local c = ("%x"):format(i);
    if (ud[i]) then
        print(("%x"):format(i), utf8.char(i), ud[i]);
    end
end

--get all ucs glyphs corresponding to undone


--replace the parts with GSource (See gw_replace)

--