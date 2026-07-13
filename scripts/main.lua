#!/bin/lua

-- Imports
unpack = unpack or table.unpack
local ok = require("okutils")
local Dirs, Mir, Env = dofile("/etc/okpkg.conf")

function basename(s) 
   return string.sub(s, #s+2-string.find(string.reverse(s), "/", 1, true)) 
end

function dirname(s) 
   return string.sub(s, 1, #s-string.find(string.reverse(s), "/", 1, true)) 
end

-- Global variables (callable by cli)
chroot, b3sum = ok.chroot, ok.b3sum

-- Make directories
for k,v in pairs(Dirs) do
   local fp = io.open(v); if fp then fp:close() else ok.create_directory(v) end
end

-- Environment variables
for k,v in pairs(Env) do ok.setenv(k,v) end

-- Build routines
B = {
   ["cargo"] = function(...)
      local arg = {
         [0] = "cargo install",
         "--path=.",
         "--root=$destdir/usr",
         "--profile=release",
         "--locked",
         "--no-track",
         ...
      }
      return os.execute(table.concat({arg[0], unpack(arg)}, " "))
   end,
   ["cmake"] = function(...)
      local arg = {
         [0] = "$cmake -B build -G Ninja -Wno-dev",
         "-DCMAKE_BUILD_TYPE=Release",
         "-DCMAKE_INSTALL_PREFIX=/",
         "-DCMAKE_INSTALL_LIBDIR=/lib64",
         "-DCMAKE_INSTALL_{,S}BINDIR=/bin",
         "-DCMAKE_INSTALL_RUNSTATEDIR=/run",
         "-DCMAKE_SHARED_LIBS=True",
         "-DCMAKE_SKIP_RPATH=TRUE",
         ...
      }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, " ")) and
         os.execute("DESTDIR=$destdir $ninja -C build install"))
   end,
   ["cmake@opt"] = function(...)
      local arg = {
         [0] = "$cmake -B build -G Ninja -Wno-dev",
         "-DCMAKE_BUILD_TYPE=Release",
         "-DCMAKE_INSTALL_LOCALSTATEDIR=/var",
         "-DCMAKE_INSTALL_RUNSTATEDIR=/run",
         "-DCMAKE_INSTALL_{,S}BINDIR=bin",
         "-DCMAKE_INSTALL_SYSCONFDIR=/etc",
         "-DCMAKE_SKIP_RPATH=TRUE",
         ...
      }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, " ")) and
         os.execute("DESTDIR=$destdir $ninja -C build install"))
   end,
   ["configure"] = function(f, ...)
      local arg = {
         [0] = f,
         "--prefix=/usr",
         ...
      }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, " ")) and
         os.execute("$make") and
         os.execute("$make install DESTDIR=$destdir"))
   end,
   ["make"] = function(...)
      local arg = {
         [0] = { "$make", "$make install DESTDIR=$destdir" },
         ...
      }
      return (
         os.execute(table.concat({arg[0][1], unpack(arg)}, " ")) and
         os.execute(table.concat({arg[0][2], unpack(arg)}, " ")))
   end,
   ["make_noinstall"] = function(...)
      local arg = {
         [0] = "$make",
         ...
      }
      return os.execute(table.concat({arg[0], unpack(arg)}, " "))
   end,
   ["make_install"] = function(...)
      local arg = {
         [0] = "$make install DESTDIR=$destdir",
         ...
      }
      return os.execute(table.concat({arg[0], unpack(arg)}, " "))
   end,
   ["meson"] = function(...)
      local arg = {
         [0] = "$meson setup build",
         "-Dprefix=/usr",
         "-Dlibdir=../lib64",
         "-D{,s}bindir=../bin",
         "-Ddebug=false",
         "-Doptimization=2",
         "-Dwrap_mode=nodownload",
         "-Dpython.install_env=system",
         ...
      }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, " ")) and
         os.execute("DESTDIR=$destdir $ninja -C build install"))
   end,
   ["perl"] = function()
      return (
         os.execute("perl Makefile.PL") and
         os.execute("$make") and
         os.execute("$make pure_install doc_install DESTDIR=$destdir"))
   end,
   ["python-build"] = function()
      return (
          os.execute("python3 -m build -nx")  and
          os.execute("python3 -m installer -d $destdir dist/*whl"))
   end,
   ["waf"] = function()
      os.execute [[
         ./waf configure --prefix=/usr --libdir=/lib64
         ./waf build
         ./waf install --destdir=$destdir
      ]]
      return true
   end,
   ["zig"] = function()
      os.execute [[
         DESTDIR=$destdir zig build \
	     --prefix "/usr" \
	     -Doptimize=ReleaseFast \
      ]]
      return true
   end,
}

local function mtime(x)
   local fp, buf
   fp = io.popen("stat -c %Y " .. x)
   buf = fp:read("*a")
   io.close(fp)
   return(tonumber(buf:sub(1, buf:find("\n")-1)))
end

function vmatch(s)
   return string.match(s, "[-_%.][nrv]?([%d%.]+%l?%d?)[-_%.]")
end

function query(x)
   local i, fp, buf
   for it in ok.directory_iterator(Dirs.tab) do
      if not buf and basename(it) ~= "cross" then
         fp = io.open(it)
         buf = "\n" .. fp:read("*a")
         fp:close()
         i = buf:find("\n" .. x .. " =", 1, true)
         if i then
            buf = buf:sub(buf:find("{", i, true), buf:find("};", i, true))
         else
            buf = false
         end
      end
   end
   return load("return " .. buf)()
end

function download(x)
   local X, fp

   X = query(x)
   X.dist = string.format("%s/%s", Dirs.distfiles, basename(X.url))

   -- change mirrors
   for k,v in pairs(Mir) do X.url = X.url:gsub(k, v) end 
   
   -- Download file if not already downloaded
   ok.current_path(Dirs.distfiles)
   io.close(
      io.open(basename(X.url)) or
      io.popen("wget2 " .. X.url))
   assert(
      X.b3sum == b3sum(basename(X.url)) or 
      not os.remove(basename(X.url)))
   
   -- Setup source directory
    ok.current_path(Dirs.src)
    ok.remove_all(x)
    ok.create_directory(x)
    ok.current_path(x)
    os.execute("tar --strip-components=1 -xf " .. X.dist)
   
   -- Patch if file exists
   -- Note: symlink for temporary packages, or update patch infrastructure
   fp = io.open(string.format("%s/%s.diff", Dirs.patches, x))
   if fp then
      io.popen("$patch", "w"):write(fp:read("*a")):close()
      fp:close()
   end

   -- Set the mtime 
   ok.setenv("SOURCE_DATE_EPOCH", mtime(X.dist))
   os.execute [[ find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]
   ok.unsetenv("SOURCE_DATE_EPOCH")

   return x
end

function makepkg(x)
   ok.current_path(x)
   os.remove(x .. ".tar.lz")
   ok.setenv("SOURCE_DATE_EPOCH", mtime("."))

   -- Stripping
   local fp = io.open(".nostrip")
   if fp then
      fp:close()
      os.remove(".nostrip")
   else
      os.execute([[
         find . -name \*.a -o -name \*.o -exec strip -g '{}' + 2>/dev/null
         find . -exec file '{}' + \
         | awk -F: '(/executable/||/shared object/)&&/ELF/{print $1}' \
         | xargs strip --strip-unneeded 2>/dev/null
      ]])
   end

   -- Delete unneeded, timestamp, etc.
   os.execute [[
      chmod -f 1777 tmp
      rm -fr usr/share/info
      rm -fr usr/share/man/{de,fr,pl,pt_BR,ro,sv,uk}
      rm -fr usr/share/{doc,locale,gtk-doc}
      find . -name \*.pyc -delete
      find . -name \*.la -delete
      $tar \
         --mtime="@$SOURCE_DATE_EPOCH" \
         --sort=name \
         --owner=0 \
         --group=0 \
         --numeric-owner \
         --lzip \
         --file=$PWD.tar.lz \
         --create .
      touch -hd "@$SOURCE_DATE_EPOCH" $PWD.tar.lz
   ]]

   -- Cleanup
   ok.current_path("..")
   ok.remove_all(x)
   ok.unsetenv("SOURCE_DATE_EPOCH")

   return x .. ".tar.lz"
end

function build(x)
   local X = query(x)
   X.flags = X.flags or {}
   X.V = vmatch(basename(X.url))
   X.destdir = string.format("%s/%s-%s-%s", Dirs.out, x, X.V, "skylake")
   ok.setenv("destdir", X.destdir)
   ok.remove_all(X.destdir)
   ok.create_directory(X.destdir)

   ok.current_path(string.format("%s/%s", Dirs.src, x))
   ok.setenv("SOURCE_DATE_EPOCH", mtime("."))

   X.prep = 
      X.prep and 
      not os.execute(X.prep) and
      error(string.format("error: build: prep: %s", x))

   if B[X.build] then
      if not B[X.build](unpack(X.flags)) then
         error(string.format("error: build: %s: %s", X.build, x))
      end
   elseif tostring(X.build):match("config") then
      -- Check if we are doing an out of tree build
      if tostring(X.build):sub(1, 2) == ".." then 
         ok.remove_all("build")
         ok.create_directory("build") 
         ok.current_path("build")
      end
      if not B["configure"](X.build, unpack(X.flags)) then
         error(string.format("error: build: %s: %s", X.build, x))
      end
   end

   X.post = 
      X.post and
      not os.execute(X.post) and
      error(string.format("error: build: post: %s", x))

   -- Set mtime
   os.execute [[ find $destdir -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]

   -- Cleanup
   ok.remove_all(X.destdir .. "no")
   ok.unsetenv("destdir")
   ok.unsetenv("SOURCE_DATE_EPOCH")

   return makepkg(X.destdir)
end

function purge(x)
   local i, fp
   local file, filename
   i = string.format("%s/%s", Dirs.log, x)
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

   fp = io.popen("$tar -C / -h -xvf " .. x)
   buf = fp:read('*a')
   fp:close()

   i = string.format("%s/%s", Dirs.log, basename(x):match("(.+)-[n%d]"))
   fp = io.open(i)
   if fp then fp:close(); os.rename(i, i .. ".orig") end
   io.close(io.open(i, "w+"):write(buf))

   os.execute("ldconfig")
end

function emerge(x)
   install(build(download(x)))
end

-- Main loop over arglist
while #arg > 1 do
   if arg[2]:sub(1,2) == "--" then
      load(arg[2]:sub(3,#arg[2]))()
   else
      _G[arg[1]](arg[2])
   end
   table.remove(arg, 2)
end

-- Return for dofile
return Dirs, Mir, Env
