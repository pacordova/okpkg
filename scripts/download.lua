#!/bin/lua

unpack = unpack or table.unpack
ok = require("okutils")
Dirs, Mir = dofile("/etc/okpkg.conf")

if #arg == 0 then
   table.insert(arg, "sys")
   table.insert(arg, "python")
   table.insert(arg, "perl")
   table.insert(arg, "devel")
   table.insert(arg, "lib")
   table.insert(arg, "net")
end

urls = {}
b3sums = {}
for i=1,#arg do
   local X, fp, buf
   fp = io.open(Dirs.tab .. "/" .. arg[i])
   buf = "\n" .. fp:read("*a")
   fp:close()
   for k,v in pairs(Mir) do buf=buf:gsub(k,v) end
   for m in buf:gmatch("\n[%w%-]-%s*=%s*({.-};)") do 
      X = load("return " .. m)()
      table.insert(urls, X.url)
      table.insert(b3sums, X.b3sum)
   end
end

function wget()
   ok.unlink(Dirs.distfiles)
   ok.mkdir(Dirs.distfiles)
   ok.chdir(Dirs.distfiles)
   fd = io.popen("/bin/wget2 -i -", "w")
   for i=1,#urls do fd:write(string.format("%s\n", urls[i])) end
   fd:close()
end

function cksum()
   assert(#urls == #b3sums)
   ok.chdir(Dirs.distfiles)
   for i=1,#urls do
      if ok.b3sum(ok.basename(urls[i])) ~= b3sums[i] then
         io.write(string.format("%s: FAILED\n", urls[i]))
         os.remove(ok.basename(urls[i]))
      end
   end
end

--wget()
cksum()
