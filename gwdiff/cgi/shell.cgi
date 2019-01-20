#!/usr/bin/lua

local util = require "cgiutil"
require "stringadd";

print("Content-type: text/html\n");
print();
local args = util:get();
if (arg[1]) then
   print(arg[1])
   args = {name = arg[1]}
end
if (args.name == nil) then
   print "Invalid Name";
   os.exit();
end

if (args.save) then
   --args.save = args.save:gsub("%%3A", ":"):gsub("%%24", "$"):gsub("%%40","@"):gsub("%%5B","["):gsub("%%5D","]");
   os.execute(("echo '%s[%s]\t%s\t%s' >> ../p.retaken.dat"):format(args.name, args.ucs, args.save, args.memo));
   os.exit();
end

args.name = args.name:split("@")[1];

--[[
local fg = io.popen(('cat ../p.original.dat ../p.origina3.dat | grep "^%s "'):format(args.name));
local content = fg:read("*all");
fg:close();

local s = content:split(" ");
if (s[3]) then
   print(s[3]);
   os.exit();
end
]]

local execcmd = function(command)
   --print(command);
   local handle = io.popen(command, "r")
   local content = handle:read("*all")
   handle:close()
   return content
end

local getjson = function(page)
   local file = "gw1205/dump_newest_only.txt";
   local cmd = ('grep "^ %s " %s'):format(page, file);
   local ret = execcmd(cmd);
   --print (ret:trim());
   local c, m = ret:trim():match('^[^ %|]+%s+%| ([^%|]+) +%| ([^ %|]+)');
   --print(c);
   --[[
   if (c) then
      c = utf8.char(tonumber(c, 16));
   end
   ]]
   --print(m);
   if (true) then
      return m, c;
   end
   
   local cmd = "curl -w '%{http_code}' http://glyphwiki.org/json?name=" .. page;
   cmd = cmd .. " -s -S"
   --print(cmd);
   local ret = execcmd(cmd);
   local m = ret:match('"data":%"([^%"]+)%"');
   local c = ret:match('"related":%"U%+([^%"]+)%"');
   if (c) then
      c = utf8.char(tonumber(c, 16));
   end
   return m, c;
end

local get_glyph = function(koseki, page)
   local data,c = getjson(koseki);
   -- 実体でなければ実体にアクセス
   --print(data,c);
   local m = (data or ""):match("^99:0:0:0:0:200:200:([^:]+)$");
   -- local m = (data or ""):match("^%[%[([^%]]+)%]%]$");
   if (m) then
      data,c = getjson(m);
   end
   return data, c;
end

local s, c = get_glyph(args.name);
print(s)
if (s) then
   --os.execute(("echo '%s %s %s' >> ../p.origina3.dat"):format(args.name, c, s));
end

--return   
