#!/usr/bin/env lua

unpack = unpack or table.unpack

local C, E, M = dofile("/etc/okpkg.conf")

local ok = require("okutils")

-- Global variables (callable by cli)
chroot, sha3sum = ok.chroot, ok.sha3sum

-- Local variables
local chdir, mkdir, setenv, unsetenv  =
   ok.chdir, ok.mkdir, ok.setenv, ok.unsetenv

local pwd = ok.pwd
local remove_all = ok.remove_all


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

local function get_timestamp(x)
   local file, buf
   file = io.popen(string.format("stat -c '%Y' %s", x)
   buf = file:read('*a')
   file:close()
   return(tonumber(buf:sub(1, buf:find('\n')-1)))
end

local function parse_version(s)
   local i, j
   s = ok.basename(s)
   j = s:find("%.[debtargz]+")
   if s:find("^%d") then 
      i = 0
   elseif s:find("[v._-]r?n?%d") then
      i = s:find("[v._-]r?n?%d")
   else
      return ""
   end
   return s:sub(i+1, j-1)
end

function _db_lookup(x)
   local file, buf, i, j
   x = string.format("\n%s = {", x)
   file = io.popen(string.format("cat %s/db/*", C["okdir"]))
   buf = '\n' .. file:read('*a')
   file:close()
   i = buf:find(x, 1, true) or
       error(string.format("error: %s not found", x))
   i = buf:find('{', i, true)
   j = buf:find('};', i, true)
   return load(string.format("return %s", buf:sub(i, j)))()
end

function download(x)
   local t, fp
   t = _db_lookup(x)

   -- Change mirrors
   for k,v in pairs(M) do t.url = t.url:gsub(k, v) end

   -- Download file if not already downloaded
   print(string.format("okpkg download %s:\nurl: '%s'", x, t.url))
   filename = string.format("%s/%s", C.distdir, ok.basename(t.url))
   file = io.open(filename)
   if file then
      file:close()
   else
      os.execute(string.format("curl -# -o %s -LR %s", filename, t.url))
   end

   -- Verify checksum
   if t.sha3 ~= sha3sum(filename) then
      os.remove(filename)
      error(string.format("%s: FAILED", ok.basename(filename)))
   else
      print(string.format("%s: OK", ok.basename(filename)))
      ok.chdir(C.workdir)
      ok.remove_all(x)
      ok.mkdir(x)
      ok.chdir(x)
      os.execute(string.format("tar --strip-components=1 -xf %s", filename))
      ok.setenv("SOURCE_DATE_EPOCH", get_timestamp(filename))
   end

   -- Patch if file exists in patches
   filename = string.format("%s/patches/%s.diff", C["okdir"], x:gsub('^_', ''))
   file = io.open(filename);
   if file then
      file:close()
      os.execute(string.format("$patch <%s", filename))
   end

   -- Set the mtime
   os.execute [[ find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]

   -- Cleanup
   ok.unsetenv("SOURCE_DATE_EPOCH")

   return x
end

function makepkg(path)
   local file
   if chdir(path) ~= 0 then
      error(string.format("error: Path `%s' does not exist", path))
   else
      ok.setenv("pwd", pwd())
      ok.setenv("SOURCE_DATE_EPOCH", get_timestamp("."))
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
          --file=$pwd.tar.lz \
          --create .
      touch -hd "@$SOURCE_DATE_EPOCH" $pwd.tar.lz
   ]]

   -- Cleanup environment
   chdir("..")
   ok.remove_all(ok.basename(path))
   ok.unsetenv("SOURCE_DATE_EPOCH")
   ok.unsetenv("pwd")

   return path .. ".tar.lz"
end

function build(x)
   local t, v, file, destdir
   t = _db_lookup(x)
   t.flags = t.flags or {}
   v = parse_version(t.url)

   -- Setup destdir
   destdir = string.format("%s/%s-%s-amd64", C["outdir"], x, C["arch"])
   ok.setenv("destdir", destdir)
   ok.mkdir(destdir)

   -- Setup workdir
   chdir(C.workdir); chdir(x)
   setenv("SOURCE_DATE_EPOCH", get_timestamp("."))

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
   remove_all(destdir .. "no")
   unsetenv("destdir")
   unsetenv("SOURCE_DATE_EPOCH")

   return makepkg(destdir)
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
   local idx, v, buf, file, filename

   -- Extract tarball, save the output buffer
   file = io.popen(string.format("tar -C / -xvhf %s 2>&1", x))
   buf = file:read('*a')
   file:close()

   v = parse_version(x)
   if #v > 0 then idx = #x-#v-8 else idx = #x-7 end
   filename = string.format("%s/%s.txt", C.indexdir, ok.basename(x:sub(1, idx)))

   -- Save original file to *.orig, use diff to delete old files
   file = io.open(filename)
   if file then
      file:close()
      os.rename(filename, filename .. ".orig")
   end

   -- Write output buffer as a file index
   file = io.open(filename, 'w')
   file:write(buf)
   file:close()

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
