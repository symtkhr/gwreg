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

-- get jmj code from kanrenji

local ret = execcmd("grep '^ jmj' ../gwdiff/cgi/gw1205/dump_newest_only.txt")
local jmj = {}
for k in ret:split_it("\n") do
    local ucs = nil;
    local a,b =    k:match('(jmj[^ ]+) +%| u3013 +%| 99:0:0:0:0:200:200:(.+)$')
    if (a) then
       ucs = b:match('^u%x+');
    else
       a,ucs =    k:match('(jmj[^ ]+) +%| (u[^ ]+) ')
    end
    if (ucs) then
       if (not jmj[ucs]) then jmj[ucs] = '' end
       jmj[ucs] = jmj[ucs] .. a;
    else
--        print(b)
    end

end
--os.exit();

local ret = execcmd('lua gw_uniqretaken.lua | grep "#jmj"')
for k in ret:split_it("\n") do

    local dkw,m =    k:match('(dkw%-[%dhd]+)%[([^%]]+)%]')
    if (m) then
        if (not m:match('^u')) then
            m = ('u%x'):format(utf8.codepoint(m));
        end
        print(("%s[%s]\t[[%s]]\t#jmj:%s"):format(dkw ,m, jmj[m], ucs2c(m)))
    --local ret = execcmd(("grep ' | %s ' ../gwdiff/cgi/gw1205/dump_newest_only.txt | grep '^ jmj'"):format(m))
    --print(m,ucs2c(m),ret)
    end
end 

