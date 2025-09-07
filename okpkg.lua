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
      "-std=gnu17",
      "-pipe" 
   },
   ["cxxflags"] = { 
      "-O2", 
      "-march=x86-64-v2", 
      "-fstack-protector-strong", 
      "-fstack-clash-protection",
      "-pipe" 
   }
}

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
         "-Dlibexecdir=libexec",
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

local function get_timestamp(filename)
   local file, buf
   file = io.popen("stat -c '%Y' " .. filename)
   buf = file:read('*a')
   file:close()
   return(tonumber(buf:sub(1, buf:find('\n')-1)))
end

local function parse_version(s) 
   local i, j
   s = basename(s)
   j = s:find("%.[debtargz]+")
   if s:find("^%d") then i = 0
   elseif s:find("[v._-]r?n?%d") then i = s:find("[v._-]r?n?%d")
   else return "" end; return s:sub(i+1, j-1)
end

function _db_lookup(x)
   local file, buf, i, j
   x = string.format("\n%s = {", x)
   file = io.popen(string.format("cat %s/*.db", C.dbpath))
   buf = '\n' .. file:read('*a')
   file:close()
   i = buf:find(x, 1, true) or 
       error(string.format("error: %s not found"))
   i = buf:find('{', i, true)
   j = buf:find('};', i, true)
   return load(string.format("return %s", buf:sub(i, j)))()
end

function download(x) 
   local t, srcdir, file, filename
   t = _db_lookup(x)

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
   filename = string.format("%s/%s", C.outdir, basename(t.url))
   file = io.open(filename)
   if file then 
      file:close()
   else 
      os.execute(string.format("curl -# -o %s -LR %s", filename, t.url))
   end
  
   -- Verify checksum 
   if t.sha3 ~= sha3sum(filename) then
      os.remove(filename)
      error(string.format("%s: FAILED", basename(f)))
   else
      chdir(srcdir)
      os.execute(string.format("tar --strip-components=1 -xf %s", filename))
      setenv("SOURCE_DATE_EPOCH", get_timestamp(filename))
      print(string.format("%s: OK", basename(filename)))
   end
      
   -- Patch if file exists in patchdir
   filename = string.format("%s/%s.diff", C.patchdir, x:gsub('^_', ''))
   file = io.open(filename);
   if file then 
      file:close()
      os.execute(string.format("$patch <%s", filename))
   end

   -- Set the mtime
   os.execute [[ find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]

   return x
end

function makepkg(path)
   local file
   if chdir(path) ~= 0 then
      error(string.format("error: Path `%s' does not exist", path))
   else
      setenv("SOURCE_DATE_EPOCH", get_timestamp("."))
   end

   -- Stripping
   file = io.open(".nostrip")
   if file then
      file:close()
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
   local t, v, file, destdir, srcdir
   t = _db_lookup(x)
   t.flags = t.flags or {}
   v = parse_version(t.url)

   -- Setup destdir
   destdir = string.format("%s/%s-%s-amd64", C.pkgdir, x, v)
   setenv("destdir", destdir)
   mkdir(destdir)

   -- Setup srcdir
   srcdir = string.format("%s/%s", C.srcpath, x)
   setenv("SOURCE_DATE_EPOCH", get_timestamp(srcdir))
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
   local file, filename
   filename = string.format("%s/%s.index", C.indexdir, x)
   file = io.open(filename)
   if file then
      for path in file:lines() do
         os.remove(path:sub(2, #path))
      end
      file:close()
      os.remove(filename)
   end
end

function install(path) 
   local v, file, buf, f

   -- Extract tarball, save the output buffer
   file = io.popen(string.format("tar -C / -xvhf %s 2>&1", path))
   buf = file:read('*a')
   file:close()

   v = parse_version(path)
   if #v > 0 then 
      f = C.indexdir .. "/" .. basename(path:sub(1, #path-#v-8)) .. ".index"
   else 
      f = C.indexdir .. "/" .. basename(path:sub(1, #path-7)) .. ".index" 
   end

   -- Save original file to *.orig, use diff to delete old files
   file = io.open(f)
   if file then 
      file:close()
      os.rename(f, f .. ".orig") 
   end

   -- Write output buffer as a file index
   file = io.open(f, 'w')
   file:write(buf)
   file:close()

   os.execute("ldconfig")
end

function emerge(x) install(build(download(x))) end

-- Environment variables
setenv("LC_ALL", "POSIX")
setenv("CONFIG_SITE", C.config_site)
setenv("CFLAGS", table.concat(C.cflags, ' '))
setenv("CXXFLAGS", table.concat(C.cxxflags, ' '))
setenv("MAKEFLAGS", "-j5")
setenv("ninja", "samu")
setenv("patch", "patch -b -p1")

-- Main loop over arglist
while #arg > 1 do
   if arg[2]:sub(1,2) == "--" then load(arg[2]:sub(3,#arg[2]))()
   else _G[arg[1]](arg[2]) end
   table.remove(arg, 2)
end
