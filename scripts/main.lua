#!/usr/bin/env lua

unpack = unpack or table.unpack

local ok = require("okutils")

-- Global variables (callable by cli)
chroot, sha3sum = ok.chroot, ok.sha3sum

local C, M, E = dofile("/etc/okpkg.conf")

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

function mkcd(x) ok.remove_all(x); ok.mkdir(x); ok.chdir(x); end

-- can replace basename.c
function basename(x) return x:match(".*/(.-)$") or x end


local function get_timestamp(x)
   local fp, buf
   fp = io.popen("stat -c '%Y' " .. x)
   buf = fp:read('*a')
   io.close(fp)
   return(tonumber(buf:sub(1, buf:find('\n')-1)))
end

local function parse_version(s)
   local i, j
   s = basename(s)
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

-- TODO: C function to listdir, iterate instead of popen
-- TODO: Don't hardcore /usr/okpkg
function look(x)
   local fp, buf
   fp = io.popen("cat /usr/okpkg/db/*")
   buf = fp:read('*a'):match("\n?" .. x .. "%s*=%s*({.-})%s*;")
   fp:close()
   return load("return " .. buf)()
end

-- TODO: make sha3sum use a file pointer (luaL_checkudata)
-- TODO: curl to stdout in io.popen and read the raw data
-- TODO: timestamp from unix headers?
function download(x)
   local X, fp

   X = look(x)
   for k,v in pairs(M) do X.url = X.url:gsub(k, v) end -- change mirrors
   X.url = { X.url:match("(.*)/(.-)$") }

   -- Download file if not already downloaded
   print(("okpkg download %s\nurl: %s/%s"):format(x, X.url[1], X.url[2]))
   ok.chdir(C.distdir)
   io.close(
      io.open(X.url[2]) or
      io.popen(("$curl -O %s/%s"):format(X.url[1], X.url[2]))
   )

   -- Verify checksum
   if not X.sha3 == ok.sha3sum(X.url[2]) then
      os.remove(X.url[2])
      error(("%s: FAILED"):format(X.url[2]))
   else
     print(("%s: OK"):format(X.url[2]))
   end

   -- Setup workdir
   X.url[1] = C["distdir"]
   ok.setenv("SOURCE_DATE_EPOCH", get_timestamp(X.url[2]))
   mkcd(("%s/%s"):format(C["workdir"], x))
   os.execute("tar --strip-components=1 -xf " .. table.concat(X.url, "/")) 

   -- Patch if file exists in patches
   fp = io.open(("%s/patches/%s.diff"):format(C.okdir, x:gsub('^_', '')))
   if fp and io.popen("$patch", 'w'):write(fp:read("*a")):close() then
      fp:close()
   end

   -- Set the mtime
   os.execute [[ find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]

   -- Cleanup
   ok.unsetenv("SOURCE_DATE_EPOCH")

   return x
end

function makepkg(path)
   if ok.chdir(path) ~= 0 then
      error(string.format("error: Path `%s' does not exist", path))
   else
      ok.setenv("pwd", ok.pwd())
      ok.setenv("SOURCE_DATE_EPOCH", get_timestamp("."))
   end

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
   ok.chdir("..")
   ok.remove_all(basename(path))
   ok.unsetenv("SOURCE_DATE_EPOCH")
   ok.unsetenv("pwd")

   return path .. ".tar.lz"
end

function build(x)
   local X, destdir
   X = look(x)
   X.flags = X.flags or {}
   local version = parse_version(X.url)
   local arch = os.getenv("CFLAGS"):match("-march=([%w%-]*)"):gsub("%-", "_")

   -- Setup destdir
   destdir = ("%s/%s-%s-%s"):format(C["outdir"], x, version, arch)
   ok.setenv("destdir", destdir)
   ok.mkdir(destdir)

   -- Setup workdir
   ok.chdir(("%s/%s"):format(C.workdir, x))
   ok.setenv("SOURCE_DATE_EPOCH", get_timestamp("."))

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
      if tostring(X.build):sub(1, 2) == ".." then mkcd("build") end
      if not B["configure"](X.build, unpack(X.flags)) then
         error(string.format("error: build: %s: %s", X.build, x))
      end
   end

   X.post = 
      X.post and
      not os.execute(X.post) and
      error(string.format("error: build: post: %s", x))

   -- Set the mtime
   os.execute [[ find $destdir -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]

   -- Cleanup
   ok.remove_all(destdir .. "no")
   ok.unsetenv("destdir")
   ok.unsetenv("SOURCE_DATE_EPOCH")

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
   filename = string.format("%s/%s.txt", C.indexdir, basename(x:sub(1, idx)))

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

-- Return for dofile
return C, M, E
