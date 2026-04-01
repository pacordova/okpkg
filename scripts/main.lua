#!/usr/bin/env lua

-- Imports
unpack = unpack or table.unpack
local ok = require("okutils")
local C, M, E = dofile("/etc/okpkg.conf")

-- Global variables (callable by cli)
chroot, sha3sum = ok.chroot, ok.sha3sum

-- Environment variables
for k,v in pairs(E) do ok.setenv(k,v) end

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
      return os.execute(table.concat({arg[0], unpack(arg)}, ' '))
   end,
   ["cmake"] = function(...)
      local arg = {
         [0] = "cmake -B build -G Ninja -Wno-dev",
         "-DCMAKE_SHARED_LIBS=True",
         "-DCMAKE_BUILD_TYPE=Release",
         "-DCMAKE_INSTALL_PREFIX=/usr",
         "-DCMAKE_SKIP_RPATH=TRUE",
         ...
      }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, ' ')) and
         os.execute("DESTDIR=$destdir $ninja -C build install"))
   end,
   ["configure"] = function(f, ...)
      local arg = {
         [0] = f,
         "--prefix=/usr",
         ...
      }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, ' ')) and
         os.execute("make") and
         os.execute("make install DESTDIR=$destdir"))
   end,
   ["make"] = function(...)
      local arg = {
         [0] = { "make", "make install DESTDIR=$destdir" },
         ...
      }
      return (
         os.execute(table.concat({arg[0][1], unpack(arg)}, ' ')) and
         os.execute(table.concat({arg[0][2], unpack(arg)}, ' ')))
   end,
   ["make_noinstall"] = function(...)
      local arg = {
         [0] = "make",
         ...
      }
      return os.execute(table.concat({arg[0], unpack(arg)}, ' '))
   end,
   ["make_install"] = function(...)
      local arg = {
         [0] = "make install DESTDIR=$destdir",
         ...
      }
      return os.execute(table.concat({arg[0], unpack(arg)}, ' '))
   end,
   ["meson"] = function(...)
      local arg = {
         [0] = "$meson setup build",
         "-Dprefix=/usr",
         "-Dlibdir=lib64",
         "-Dsbindir=bin",
         "-Dlibexecdir=lib64",
         "-Ddebug=false",
         "-Doptimization=2",
         "-Dwrap_mode=nodownload",
         ...
      }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, ' ')) and
         os.execute("DESTDIR=$destdir $ninja -C build install"))
   end,
   ["perl"] = function()
      return (
         os.execute("perl Makefile.PL") and
         os.execute("make") and
         os.execute("make pure_install doc_install DESTDIR=$destdir"))
   end,
   ["python-build"] = function()
      return (
          os.execute("python3 -m build -nx")  and
          os.execute("python3 -m installer -d $destdir dist/*whl"))
   end,
   ["waf"] = function()
      os.execute [[
         ./waf configure --prefix=/usr --libdir=/usr/lib64
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
   buf = fp:read('*a')
   io.close(fp)
   return(tonumber(buf:sub(1, buf:find('\n')-1)))
end

local function v(x)
   return ok.basename(x):match("[-_%.][a-z]?([%d%.]+[a-z]?[0-9]?)[-_%.]")
end


-- TODO: C function to listdir, iterate instead of popen
-- TODO: Don't hardcode /usr/okpkg
function _XLOOK (x)
   local fp, buf
   x = x:gsub("%-", "%%-")
   fp = io.popen("cat /usr/okpkg/db/*")
   buf = fp:read('*a'):match("\n?[^%w]" .. x .. "%s*=%s*({.-})%s*;")
   fp:close()
   return load("return " .. buf)()
end

function download(x)
   local X = _XLOOK (x)
   X.dist = string.format("%s/%s", C.distdir, X.url:match("/([^/]*)$"))

   -- change mirrors
   for k,v in pairs(M) do X.url = X.url:gsub(k, v) end 
   
   -- Download file if not already downloaded
   io.close (
      io.open(X.dist) or 
      io.popen(string.format("$curl %s >%s", X.url, X.dist))
   )
   assert(X.sha3 == sha3sum(X.dist) or not os.remove(X.dist))
   
   -- Setup source directory
   assert(
      ok.chdir(C["workdir"]) and 
      ok.remove_all(x) and 
      ok.mkdir(x) and 
      ok.chdir(x) and
      os.execute("$tar --strip-components=1 -xf " .. X.dist)
   )
   
   -- Patch if file exists
   -- Note: symlink for temporary packages, or update patch infrastructure
   local patchfile = io.open(string.format("/usr/okpkg/patches/%s.diff", x))
   if patchfile then
      io.popen("$patch", 'w'):
         write(patchfile:read("*a")):
         close()
      patchfile:close()
   end

   -- Set the mtime 
   ok.setenv("SOURCE_DATE_EPOCH", mtime(X.dist))
   os.execute [[ find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]
   ok.unsetenv("SOURCE_DATE_EPOCH")

   return x
end

function makepkg(path)
   assert(ok.chdir(path) == 0)
   ok.setenv("pwd", ok.pwd())
   ok.setenv("SOURCE_DATE_EPOCH", mtime("."))

   -- Stripping
   io.close(
      (io.open(".nostrip") and os.remove(".nostrip")) or
      io.popen [[
         find . -name \*.a -o -name \*.o -exec strip -g '{}' + 2>/dev/null
         find . -exec file '{}' + \
         | awk -F: '(/executable/||/shared object/)&&/ELF/{print $1}' \
         | xargs strip --strip-unneeded 2>/dev/null
      ]]
   )

   -- Delete unneeded, timestamp, etc.
   os.execute [[
      rm -fr usr/share/man/{de,fr,pl,pt_BR,ro,sv,uk}
      rm -fr usr/share/{info,doc,locale,gtk-doc}
      find . -name \*.pyc -delete
      find . -name \*.la -delete
      $tar --mtime="@$SOURCE_DATE_EPOCH" \
          --sort=name \
          --owner=0 \
          --group=0 \
          --numeric-owner \
          --use-compress-program="lzip -f" \
          --file=$pwd.tar.lz \
          --create .
      touch -hd "@$SOURCE_DATE_EPOCH" $pwd.tar.lz
   ]]

   -- Cleanup
   ok.chdir("..")
   ok.remove_all(path)
   ok.unsetenv("SOURCE_DATE_EPOCH")
   ok.unsetenv("pwd")

   return path .. ".tar.lz"
end

function build(x)
   local X = _XLOOK (x)
   X.flags = X.flags or {}
   X.version = v(X.url) or "nil"
   X.destdir = string.format("%s/%s-%s-%s", C.outdir, x, X.version, C.cc.cpu)

   ok.setenv("destdir", X.destdir)
   ok.remove_all(X.destdir)
   ok.mkdir(X.destdir)

   -- Setup workdir
   ok.chdir(("%s/%s"):format(C.workdir, x))
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
         ok.mkdir("build") 
         ok.chdir("build")
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
   local file, filename
   filename = string.format("%s/%s.txt", C.indexdir, x)
   file = io.open(filename)
   if file then
      for path in file:lines() do
         os.remove(path:sub(2, #path))
      end
      file:close()
      os.remove(filename)
   end
end

function install(x)
   local fp, buf, txt

   fp = io.popen("$tar -C / -xvf " .. x)
   buf = fp:read('*a')
   io.close(fp)

   ok.chdir(C.indexdir)
   txt = ok.basename(x):match("(.+)-[n%d]") .. ".txt"
   os.rename(txt, txt .. ".orig")
   io.close(io.open(txt, 'w'):write(buf))

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
return C, M, E
