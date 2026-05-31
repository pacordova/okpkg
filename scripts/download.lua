#!/bin/lua

unpack = unpack or table.unpack
ok = require("okutils")
Dirs, Mir = dofile("/etc/okpkg.conf")

tabs = { "sys", "python", "perl", "devel", "lib", "net" } 

urls = {}
sha3sums = {}
for i=1,#tabs do
   local X, fp, buf
   fp = io.open(Dirs.tab .. "/" .. tabs[i])
   buf = "\n" .. fp:read("*a")
   fp:close()
   for k,v in pairs(Mir) do buf=buf:gsub(k,v) end
   for m in buf:gmatch("\n[%w%-]-%s*=%s*({.-};)") do 
      X = load("return " .. m)()
      table.insert(urls, X.url)
      table.insert(sha3sums, X.sha3)
   end
end

-- download
ok.remove_all(Dirs.distfiles)
ok.mkdir(Dirs.distfiles)
ok.chdir(Dirs.distfiles)
fd = io.popen("/bin/wget2 -i -", "w")
for i=1,#urls do fd:write(string.format("%s\n", urls[i])) end
fd:close()

-- cksum
assert(#urls == #sha3sums)
for i=1,#urls do
   if ok.sha3sum(ok.basename(urls[i])) ~= sha3sums[i] then
      io.write(string.format("%s: FAILED\n", urls[i]))
      os.remove(ok.basename(urls[i]))
   end
end
