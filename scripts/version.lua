#!/usr/bin/env lua

unpack = unpack or table.unpack

ok = require("okutils")
C = dofile("/etc/okpkg.conf")


function popen(command)
   local fp, buf
   fp = io.popen(command)
   buf = fp:read("*a")
   fp:close()
   return buf
end

function curl(x)
   return popen("curl -#L https://mirrors.kernel.org/" .. x)
end

function v(t, x)
   for i=1,#t do
      if t[i]:match("^" .. x .. "%-%d") then
         return ok.basename(t[i]):match("[-_%.:][nrv]?([%d%.]+%l?%d?)[-_%.+]")
      end
   end
   return ""
end

---------------
-- archlinux --
---------------
archlinux = {}
archlinux[0] = curl"archlinux/{core,extra,community}/os/x86_64/"
for w in archlinux[0]:gmatch('>([^%s]-.tar.zst)<') do
   local fixed = w:
       gsub("-x86_64", ""):
       gsub("%-%d+$", ""):
       gsub("%d%%%dA", ""):
       gsub("%%%dB.*", ""):
       gsub("_a", "a"):
       gsub("python%-3", "python3-3"):
       gsub("libnl%-", "libnl3-"):
       gsub("libisl%-", "isl-"):
       gsub("gcr%-4", "gcr4"):
       gsub("ffnvcodec", "nv-codec"):
       gsub("gnupg%-", "gnupg2-"):
       gsub("bash.5.3.9", "bash-5.3.009")
   table.insert(archlinux, fixed)
end

-----------------------
-- slackware-current --
-----------------------
slackware = {}
slackware[0] = curl"slackware/slackware64-current/slackware64/FILE_LIST"
for w in slackware[0]:gmatch('%./[^/]-/([^%s]-txz)\n') do
   local fixed = w:
      gsub("-x86_64", ""):
      gsub("glibc%-zoneinfo%-", "tzdata-"):
      gsub("bash%-completion%-", ""):
      gsub("lvm2%-", "device-mapper-"):
      gsub("gtk%+3%-", "gtk3-"):
      gsub("gtkmm%-", "gtkmm3-")
   table.insert(slackware, fixed)
end

-----------
-- okpkg --
-----------
ok.chdir(C.pkgdir)
okpkg = {}
for w in string.gmatch(popen("ls *.tar.lz"), '(.-\n)') do
   local fixed = w:
      gsub("-x86_64", ""):
      gsub("-amd64", ""):
      gsub("rust%-bin", "rust"):
      gsub("cmake%-bin", "cmake")
   table.insert(okpkg, fixed)
end

--------------
-- main loop -
--------------
-- Skip version checks on these packages, comma delimiter
-- TODO: fix dashes not working in list, escape does not fix
skip = "bc,cmake,librsvg,pavucontrol,python3,vim,x264"

L = {}
L[0] = '\n' .. popen("cat /usr/okpkg/db/*")
for i in L[0]:gmatch("\n([%w%-%+]-) = {.-;") do
   if not string.format(",%s,", skip):
      match(string.format(",%s,", i)) 
   then
      table.insert(L, i)
   end
end

-- Output
io.write("package,archlinux,slackware,okpkg\n")
for i=1,#L do
   local x = L[i]:gsub("%-", "%%-")
   local r = {
      v(archlinux, x),
      v(slackware, x:gsub("xorg%%%-", "")),
      v(okpkg, x),
   }
   if ((#r[3]>0 and #r[2]>0 and r[3] ~= r[2]) or
       (#r[3]>0 and #r[1]>0 and r[3] ~= r[1]))
   then
      io.write(string.format("%s,%s,%s,%s\n", L[i], unpack(r)))
   end
end
