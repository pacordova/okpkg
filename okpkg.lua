#!/usr/bin/env lua

-- Imports
local unpack = unpack or table.unpack
local ok = require("okutils")

-- Global variables (callable by cli)
chroot, sha3sum = ok.chroot, ok.sha3sum

-- Local variables
local chdir, mkdir, pwd, basename, dirname, setenv, unsetenv  =
   ok.chdir, ok.mkdir, ok.pwd, ok.basename, ok.dirname, ok.setenv, ok.unsetenv

-- Configuration
C = {
   ["gnu"] = "http://mirror.fcix.net",
   ["cran"] = "https://archive.linux.duke.edu/cran",
   ["pkgdir"] = "/var/lib/okpkg/packages",
   ["okpath"] = "/var/lib/okpkg",
   ["dbpath"] = "/var/lib/okpkg/db",
   ["outdir"] = "/var/lib/okpkg/download",
   ["srcpath"] = "/var/lib/okpkg/sources",
   ["indexdir"] = "/var/lib/okpkg/index",
   ["patchdir"] = "/var/lib/okpkg/patches",
   ["config_site"] = "/etc/config.site",
   ["ninja"] = "/usr/bin/samu",
   ["jobs"] = 5,
   ["cflags"] = { 
      "-O2", 
      "-march=x86-64-v2", 
      "-fstack-protector-strong", 
      "-fstack-clash-protection",
      "-fcommon",
      "-pipe" 
   }
}

-- Build routines
B = {
   ["b2"] = function(...)
      local arg = {
         [0] = "$b2",
         "-j5",
         "variant=release",
         "toolset=gcc",
	 ...,
         "install",
         "--prefix=$destdir/usr",
         "--libdir=$destdir/usr/lib64",
      }
      return os.execute(table.concat({arg[0], unpack(arg)}, ' '))
   end,
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
   ["meson"] = function(...)
      local arg = {
         [0] = "meson setup build",
         "-Dprefix=/usr",
         "-Dlibdir=lib64",
         "-Dsbindir=bin",
         "-Dlibexecdir=lib64",
         "-Dbuildtype=release",
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

local function timestamp(f)
   local fp, buf
   fp = io.popen("stat -c '%Y' " ..  f)
   buf = fp:read('*a')
   fp:close()
   buf = buf:sub(1, buf:find('\n')-1)
   return(tonumber(buf))
end

local function vstr(s) 
   local i, j
   s = basename(s)
   j = s:find("%.[debtargz]+")
   if s:find("^%d") then i = 0
   elseif s:find("[v._-]r?n?%d") then i = s:find("[v._-]r?n?%d")
   else return "" end; return s:sub(i+1, j-1)
end

local function vlook(k)
   local fp, buf, i, j
   k = string.format("\n%s = {", k)
   fp = io.popen(string.format("cat %s/*.db", C.dbpath))
   buf = '\n' .. fp:read('*a')
   fp:close()
   i = buf:find(k, 1, true)
   if i then 
      i = buf:find('{', i, true)
      j = buf:find('};', i, true)
      return load(string.format("return %s", buf:sub(i, j)))()
   end
end

function download(x) 
   local t, f, fp, srcdir
   t = vlook(x)

   -- Change mirrors
   t.url = t.url:
      gsub("https://ftp.gnu.org", C.gnu):
      gsub("https://cran.r%-project.org", C.cran)

   -- Delete old files
   srcdir = string.format("%s/%s", C.srcpath, x)
   os.execute(string.format("rm -fr %s", srcdir))
   mkdir(srcdir)

   -- Download file if not already downloaded
   print(string.format("okpkg download %s:\nurl: '%s'", x, t.url))
   f = string.format("%s/%s", C.outdir, basename(t.url))
   fp = io.open(f)
   if fp then 
      fp:close()
   else 
      os.execute(string.format("curl -# -o %s -LR %s", f, t.url))
   end
  
   -- Verify checksum 
   if t.sha3 ~= sha3sum(f) then
      os.remove(f)
      error(string.format("%s: FAILED", basename(f)))
   else
      chdir(srcdir)
      os.execute(string.format("tar --strip-components=1 -xf %s", f))
      setenv("SOURCE_DATE_EPOCH", timestamp(f))
      print(string.format("%s: OK", basename(f)))
   end
      
   -- Patch if file exists in patchdir
   f = string.format("%s/%s.diff", C.patchdir, x:gsub('^_', ''))
   fp = io.open(f);
   if fp then fp:close(); os.execute(string.format("$patch <%s", f)); end

   -- Set the mtime
   os.execute [[ find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]

   return x
end

function makepkg(path)
   if chdir(path) ~= 0 then
      error(string.format("error: Path `%s' does not exist", path))
   else
      setenv("SOURCE_DATE_EPOCH", timestamp("."))
   end

   -- Stripping
   local fp = io.open(".nostrip")
   if fp then
      fp:close()
      os.remove(".nostrip")
   else
      os.execute [[
         find . -name \*.a -o -name \*.o -exec strip -g '{}' + 2>/dev/null
         find . | \
             xargs file | \
             grep -e "executable" -e "shared object" | \
             grep ELF | \
             cut -f 1 -d : | \
             xargs strip --strip-unneeded 2>/dev/null
      ]]
   end

   -- Delete unneeded, timestamp, etc.
   os.execute [[
      rm -fr usr/share/man/{de,fr,pl,pt_BR,ro,sv,uk}
      rm -fr usr/share/{info,doc,locale,gtk-doc}
      find . -name \*.pyc -delete
      find . -name \*.la -delete
      tar --mtime="@$SOURCE_DATE_EPOCH" \
          --sort=name \
          --owner=0 \
          --group=0 \
          --numeric-owner \
          --use-compress-program="lzip -f" \
          --file=$PWD.tar.lz \
          --create .
      touch -hd "@$SOURCE_DATE_EPOCH" $PWD.tar.lz
   ]]

   -- Cleanup environment
   chdir("..")
   os.execute(string.format("rm -fr %s", basename(path)))
   unsetenv("SOURCE_DATE_EPOCH")

   return string.format("%s.tar.lz", path)
end

function build(x) 
   local t, v, fp, destdir, srcdir
   t = vlook(x)
   t.flags = t.flags or {}
   v = vstr(t.url)

   -- Setup destdir
   destdir = string.format("%s/%s-%s-amd64", C.pkgdir, x, v)
   setenv("destdir", destdir)
   mkdir(destdir)

   -- Setup srcdir
   srcdir = string.format("%s/%s", C.srcpath, x)
   setenv("SOURCE_DATE_EPOCH", timestamp(srcdir))
   chdir(srcdir)

   if t.prepare then 
      if not os.execute(t.prepare) then 
         error(string.format("error: build: prepare: %s", x))
      end
   end

   if B[t.build] then
      if not B[t.build](unpack(t.flags)) then 
         error(string.format("error: build: %s: %s", t.build, x))
      end
   elseif tostring(t.build):match("config") then
      -- Check if we are doing an out of tree build
      if tostring(t.build):sub(1, 2) == ".." then 
         mkdir("build") 
         chdir("build") 
      end
      if not B["configure"](t.build, unpack(t.flags)) then
         error(string.format("error: build: %s: %s", t.build, x))
      end
   end

   if t.post then
      if not os.execute(t.post) then
         error(string.format("error: build: post: %s", x))
      end
   end


   -- Set the mtime
   os.execute [[ find $destdir -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]

   -- Cleanup
   os.execute[[ rm -fr "$destdir"no ]]
   unsetenv("destdir")
   unsetenv("SOURCE_DATE_EPOCH")

   return makepkg(destdir)
end

function purge(x)
   local fp, f
   f = string.format("%s/%s.index", C.indexdir, x)
   fp = io.open(f)
   if fp then
      for path in fp:lines() do os.remove(path:sub(2, #path)) end
      fp:close(); os.remove(f)
   end
end

function install(path) 
   local v, fp, buf, f

   -- Extract tarball, save the output buffer
   fp = io.popen(string.format("tar -C / -xvhf %s 2>&1", path))
   buf = fp:read('*a')
   fp:close()

   v = vstr(path)
   if #v > 0 then 
      f = C.indexdir .. "/" .. basename(path:sub(1, #path-#v-8)) .. ".index"
   else 
      f = C.indexdir .. "/" .. basename(path:sub(1, #path-7)) .. ".index" 
   end

   -- Save original file to *.orig, use diff to delete old files
   fp = io.open(f)
   if fp then 
      fp:close()
      os.rename(f, f .. ".orig") 
   end

   -- Write output buffer as a file index
   fp = io.open(f, 'w')
   fp:write(buf)
   fp:close()

   os.execute("ldconfig")
end

function emerge(x) install(build(download(x))) end

-- Environment variables
setenv("LC_ALL", "POSIX")
setenv("CONFIG_SITE", C.config_site)
setenv("CFLAGS", table.concat(C.cflags, ' '))
setenv("CXXFLAGS", table.concat(C.cflags, ' '))
setenv("MAKEFLAGS", "-j5")
setenv("BOOST_ROOT", "/var/lib/boost_1_88_0")
setenv("b2", "/var/lib/boost_1_88_0/tools/build/src/engine/b2")
setenv("ninja", "samu")
setenv("patch", "patch -b -p1")

-- Main loop over arglist
while #arg > 1 do
   if arg[2]:sub(1,2) == "--" then load(arg[2]:sub(3,#arg[2]))()
   else _G[arg[1]](arg[2]) end
   table.remove(arg, 2)
end
