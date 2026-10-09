#!/bin/lua

ok  = require("okutils")
cfg = require("okconfig")

unpack = unpack or table.unpack
chroot, b3sum = ok.chroot, ok.b3sum

meta = {__tostring = function(x) return table.concat(x, ' ') end}

rc = {
   ["cmake"] = function(...)
      local arg = {
         "cmake",
         "-Bbuild",
         "-DCMAKE_BUILD_TYPE=Release",
         "-DCMAKE_INSTALL_BINDIR=/bin",
         "-DCMAKE_INSTALL_LIBDIR=/lib64",
         "-DCMAKE_INSTALL_PREFIX=/",
         "-DCMAKE_INSTALL_RUNSTATEDIR=/run",
         "-DCMAKE_INSTALL_SBINDIR=/bin",
         "-DCMAKE_SHARED_LIBS=True",
         "-DCMAKE_SKIP_RPATH=TRUE",
         "-GNinja",
         "-Wno-dev",
         ...
      }
      setmetatable(arg, meta)
      return os.execute(tostring(arg)) and rc.ninja()
   end,
   ["configure"] = function(...)
      local arg = {
         "sh", 
         ok.exists("configure") or
         ok.exists("../configure") or 
         ok.exists("configure.gnu"),
         "--prefix=/usr",
         ...
      }
      setmetatable(arg, meta)
      return os.execute(tostring(arg)) and rc.make()
   end,
   ["make"] = function(...)
      return rc.make_all(...) and rc.make_install(...)
   end,
   ["make_all"] = function(...)
      local arg = setmetatable({"make", ...}, meta)
      return os.execute(tostring(arg))
   end,
   ["make_install"] = function(...)
      local arg = setmetatable({"make", "install", ...}, meta)
      return (
         ok.setenv("DESTDIR", destdir) and
         os.execute(tostring(arg)) and
         ok.unsetenv("DESTDIR"))
   end,
   ["meson"] = function(...)
      local arg = {
         "meson",
         "setup",
         "build",
         "-Dprefix=/usr",
         "-Dbindir=../bin",
         "-Dlibdir=../lib64",
         "-Dsbindir=../bin",
         "-Ddebug=false",
         "-Doptimization=2",
         "-Dpython.install_env=system",
         "-Dwrap_mode=nodownload",
         ...
      }
      setmetatable(arg, meta)
      return os.execute(tostring(arg)) and rc.ninja()
   end,
   ["ninja"] = function()
      return (
         ok.setenv("DESTDIR", destdir) and
         os.execute("ninja -C build install") and
         ok.unsetenv("DESTDIR"))
   end,
   ["python"] = function()
      return (
          os.execute("python3 -m build -nx")  and
          ok.setenv("DESTDIR", destdir) and
          os.execute("python3 -m installer -d $DESTDIR dist/*whl") and
          ok.unsetenv("DESTDIR"))
   end,
}

function vmatch(s)
   return string.match(s, "[-_%.][nrv]?([%d%.]+%l?%d?)[-_%.]")
end

function query(k)
   local fp, i, len, fcn
   for de in dir(cfg.datadir) do
      if de ~= "cross.db" then
         fp = io.open(string.format("%s/%s", cfg.datadir, de))
         i = string.find(fp:read("*a"), string.format("[%q]", k), 1, true)
         if fp:seek("set", i) > 0 then
            i = fp:seek("set", i+string.find(fp:read("*a"), "{", 1, true)-1)
            len = string.find(fp:read("*a"), "};", 1, true)
            fp:seek("set", i)
            fcn = load("return " .. fp:read(len))
         end
         fp:close()
         if fcn then return fcn() end
      end
   end
end

function download(x)
   local tbl, fp

   tbl = query(x)
   tbl.dist = string.format("%s/%s", cfg.distdir, ok.basename(tbl.url))

   -- change mirrors
   --for k,v in pairs(M) do tbl.url = tbl.url:gsub(k, v) end 
   
   -- Download file if not already downloaded
   ok.chdir(cfg.distdir)
   io.close(
      io.open(ok.basename(tbl.url)) or
      io.popen("wget2 " .. tbl.url))
   assert(
      tbl.b3sum == b3sum(ok.basename(tbl.url)) or 
      not os.remove(ok.basename(tbl.url)))
   
   -- Setup source directory
    ok.chdir(cfg.wrkobjdir)
    ok.remove_all(x)
    ok.mkdir(x)
    ok.chdir(x)
    os.execute("tar --strip=1 -xf " .. tbl.dist)
   
   -- Patch if file exists
   fp = io.open(string.format("%s/patches/%s.diff", cfg.basedir, x))
   if fp then
      io.popen("patch -p 1", "w"):write(fp:read("*a")):close()
      fp:close()
   end

   -- Set the mtime 
   ok.setenv("SOURCE_DATE_EPOCH", ok.mtime(tbl.dist))
   os.execute [[ find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]
   ok.unsetenv("SOURCE_DATE_EPOCH")
   return x
end

function strip(x)
   local fp, buf
   if os.remove("nostrip") then return end
   if ok.isdir(x) then
      for de in dir(x) do strip(string.format("%s/%s", x, de)) end
   else
      fp = io.open(x, "rb")
      buf = string.pack("b", fp:read(4):byte(1, 4))
      if buf == string.pack("b", 127, 69, 76, 70) and fp:seek("set", 16) then
         buf = fp:read(1):byte()
         if buf == 1 then
            os.execute("strip --strip-debug " .. x)
         end
         if buf == 2 or buf == 3 then
            os.execute("strip --strip-unneeded " .. x)
         end
      end
      if fp:seek("set") and fp:read(7) == "!<arch>" then
         os.execute("strip --strip-debug " .. x)
      end
      fp:close()
   end
end

function makepkg(x)
   ok.chdir(x)
   ok.setenv("SOURCE_DATE_EPOCH", ok.mtime("."))

   strip(".")

   if ok.isdir("./usr/share/man") then
      for de in dir("./usr/share/man") do
         if not string.match(de, "[1-9]") then 
            ok.remove_all(string.format("%s/%s", "./usr/share/man", de))
         end
      end
   end
   ok.remove_all("./usr/share/info")
   ok.remove_all("./usr/share/doc")
   ok.remove_all("./usr/share/gtk-doc")
   ok.remove_all("./usr/share/locale")
   os.execute [[ 
      find . -name \*.pyc -o -name \*.la -delete
      tar --lzip --sort=name \
          --mtime="@${SOURCE_DATE_EPOCH}" \
          --owner=0 --group=0 --numeric-owner \
          -cf ${PWD}.tar.lz .
      touch -hd "@${SOURCE_DATE_EPOCH}" ${PWD}.tar.lz 
   ]]

   -- ::cleanup::
   ok.chdir("..")
   ok.remove_all(x)
   ok.unsetenv("SOURCE_DATE_EPOCH")
   return string.format("%s.%s", x, "tar.lz")
end

function build(x)
   ok.chdir(string.format("%s/%s", cfg.wrkobjdir, x))
   local tbl = query(x)
   destdir = string.format(
      "%s/%s-%s-%s",
      cfg.pkgdir,
      x,
      vmatch(ok.basename(tbl.url)),
      string.gsub(cfg.cpu, "-", "_")
   )
   ok.setenv("destdir", destdir)
   ok.setenv("SOURCE_DATE_EPOCH", ok.mtime("."))
   ok.remove_all(destdir)
   ok.mkdir(destdir)

   if tbl.prep and not os.execute(tbl.prep) then
      error("okpkg: build: prep script failed for " .. x)
   end

   if not tbl.build(unpack(tbl.flags or {})) then
      error("okpkg: build: " .. x)
   end

   if tbl.post and
      ok.setenv("DESTDIR", destdir) and
      not os.execute(tbl.post) and
      ok.unsetenv("DESTDIR")
   then
      error("okpkg: build: post script failed for " .. x)
   end

   -- ::cleanup::
   os.execute [[ find $destdir -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]
   os.remove(destdir .. "no")
   ok.unsetenv("destdir")
   ok.unsetenv("SOURCE_DATE_EPOCH")
   return makepkg(destdir)
end

function purge(x)
   local i, fp
   i = string.format("%s/%s", cfg.state, x)
   fp = io.open(i)
   if fp then
      for x in fp:lines() do
         os.remove(x:sub(2, #x))
      end
      fp:close()
      os.remove(i)
   end
end

function install(x)
   local i, fp, buf
   fp = io.popen("tar -C / -h -xvf " .. x)
   buf = fp:read('*a')
   fp:close()
   i = string.format("%s/%s", cfg.state, ok.basename(x):match("(.+)-[n%d]"))
   fp = io.open(i)
   if fp then fp:close(); os.rename(i, i .. ".orig") end
   io.close(io.open(i, "w+"):write(buf))
   os.execute("ldconfig")
   os.execute("chmod 1777 /tmp")
end

function emerge(x)
   install(build(download(x)))
end

--------------------------------------------------------------------------------

setmetatable(cfg.cflags, meta)
table.insert(cfg.cflags, "-march=" .. cfg.cpu)
ok.setenv("CFLAGS",   tostring(cfg.cflags))
ok.setenv("CXXFLAGS", tostring(cfg.cflags))
ok.setenv("CONFIG_SITE", cfg.site)
ok.setenv("MAKEFLAGS", "-j" .. cfg.jobs)
ok.setenv("LC_ALL", "C")

while #arg > 1 do
   if arg[2]:sub(1,2) == "--" then
      load(arg[2]:sub(3,#arg[2]))()
   else
      _G[arg[1]](arg[2])
   end
   table.remove(arg, 2)
end
