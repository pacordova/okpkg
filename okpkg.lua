#!/usr/bin/env lua

-- imports
local unpack = unpack or table.unpack
local ok = require"okutils"
local chdir, setenv, unsetenv, basename, mkdir, pwd, sha3sum =
   ok.chdir, ok.setenv, ok.unsetenv, ok.basename, ok.mkdir, ok.pwd, ok.sha3sum

-- environment
setenv("CFLAGS", "-O2 -march=x86-64-v2 -fstack-protector-strong -fstack-clash-protection -fcommon -pipe")
setenv("CXXFLAGS", os.getenv("CFLAGS"))
setenv("LC_ALL", "POSIX")
setenv("make", "make -j5")


-- TODO: unlink syscall and cfunction, recursive
local function unlink(path)
   os.execute(string.format("rm -fr %s", path))
end

-- set SOURCE_DATE_EPOCH to a mtime of a file
local function source_date_epoch(filename) local fp, buf
   fp = io.popen("stat -c '%Y' " .. filename)
   buf = fp:read('*a')
   fp:close()
   buf = buf:sub(1, buf:find('\n')-1)
   setenv("SOURCE_DATE_EPOCH", tonumber(buf))
end

local function vstr(path) local f, i, j
   f = basename(path)
   j = f:find("%.t")
   if f:find("^%d") then i = 0
   elseif f:find"[v._-]%d" then i = f:find"[v._-]%d"
   else return "" end; return f:sub(i+1, j-1)
end

local function vlook(pkgname) local db, fp, buf, i, j
   db = { "system", "modules", "extra", "lib", "xorg", "xfce" }
   for n=1,#db do
      fp = io.open(string.format("/usr/okpkg/db/%s.db", db[n]))
      buf = '\n' .. fp:read('*a')
      fp:close()
      i = buf:find(string.format("\n%s = {", pkgname), 1, true)
      if i then i = buf:find('{', i, true); j = buf:find('};', i, true)
         return load(string.format("return %s", buf:sub(i, j)))()
      end
   end
end

function download(pkgname) local t, f, fp
   t = vlook(pkgname)

-- change mirrors
t.url = t.url:
gsub("https://ftp.gnu.org", "http://mirror.rit.edu"):
gsub("https://cran.r%-project.org", "https://archive.linux.duke.edu/cran")

   -- fresh build the sources
   chdir"/usr/okpkg/sources"; unlink(pkgname); mkdir(pkgname)

   -- download file if not already downloaded
   chdir"/usr/okpkg/download"
   f = basename(t.url)
   print(string.format("okpkg download %s:\nurl: '%s'", pkgname, t.url))
   fp = io.open(f)
   if fp then fp:close()
   else os.execute(string.format("curl -LOR %s", t.url)) end

   -- set the timestamp to the mtime of the archive
   -- github timestamps must be set by hand
   source_date_epoch(f)

   -- checksum to verify the authenticity of the tarball
   if t.sha3 ~= sha3sum(f) then
      os.remove(f); error(string.format("error: bad checksum for %s", f))
   else
      print(string.format("%s: OK", f))
   end

   -- extract the sources to srcdir
   os.execute(string.format(
      "tar -C ../sources/%s --strip-components=1 -xf %s", pkgname, f))

   -- patch the sources
   chdir(string.format("/usr/okpkg/sources/%s", pkgname))
   f = string.format("../../patches/%s.diff", pkgname:gsub('^_', ''))
   fp = io.open(f);
   if fp then fp:close(); os.execute(string.format("patch -p1 <%s", f)); end

   -- touch all extracted files to SOURCE_DATE_EPOCH
   os.execute [[ find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]
end

function makepkg(path)
   -- ensure path exists
   if chdir(path) ~= 0 then
      error(string.format("error: Path `%s' does not exist", path))
   else
      source_date_epoch"."; setenv("pwd", pwd()); path = basename(path)
   end

   -- strip, delete-unneeded, timestamp, etc.
   os.execute [[
      find . -name "*.pyc" -delete
      find . -name "*.la" -delete
      find . -name "lib*a" -exec strip -g '{}' + 2>/dev/null
      find . | xargs file | grep "executable" | grep ELF | cut -f 1 -d : | \
        xargs strip --strip-unneeded 2>/dev/null
      find . | xargs file | grep "shared object" | grep ELF | \
        cut -f 1 -d : | xargs strip --strip-unneeded 2>/dev/null
      rm -fr usr/doc usr/share/{info,doc,locale,gtk-doc}
      rm -fr usr/share/man/{de,fr,pl,pt_BR,ro,sv,uk}
      tar --mtime="@$SOURCE_DATE_EPOCH" --sort=name --owner=0 --group=0 \
        --numeric-owner -cf $pwd.tar .
      lzip -f $pwd.tar
      touch -hd "@$SOURCE_DATE_EPOCH" $pwd.tar.lz
   ]]

   -- cleanup
   chdir".."
   unlink(path)
   unsetenv"pwd"
   unsetenv"SOURCE_DATE_EPOCH"

   return path..".tar.lz"
end

function build(pkgname) local t, v, status, destdir, fp
   t = vlook(pkgname); t.flags = t.flags or {}
   v = vstr(t.url)
   status = true
   destdir = string.format("/usr/okpkg/packages/%s-%s-x86_64", pkgname, v)

   setenv("destdir", destdir); mkdir(destdir)

   chdir"/usr/okpkg/sources"; chdir(pkgname)
   source_date_epoch"."

   if t.prepare then os.execute(t.prepare) end

   if t.build == "./autogen.sh" then
      table.insert(t.flags,  1, "--prefix=/usr")
      t.flags = table.concat(t.flags, ' ')
      status =
         os.execute"./autogen.sh" and
         os.execute(string.format("./configure %s", t.flags)) and
         os.execute"$make" and
         os.execute"$make install DESTDIR=$destdir"
   end

   if t.build == "autoreconf" then
      table.insert(t.flags,  1, "--prefix=/usr")
      t.flags = table.concat(t.flags, ' ')
      status =
         os.execute"autoreconf -fi" and
         os.execute(string.format("./configure %s", t.flags)) and
         os.execute"$make" and
         os.execute"$make install DESTDIR=$destdir"
   end

   if tostring(t.build):match("config") then
      table.insert(t.flags,  1, "--prefix=/usr")
      t.flags = table.concat(t.flags, ' ')

      -- for gcc, glibc, etc, use separate builddir
      if t.build:sub(1, 2) == ".." then mkdir"build"; chdir"build"; end

      status =
         os.execute(string.format("%s %s", t.build, t.flags)) and
         os.execute"$make" and
         os.execute"$make install DESTDIR=$destdir"
   end

   if t.build == "cmake" then
      mkdir"build"; chdir"build"
      table.insert(t.flags, 1, "-DCMAKE_INSTALL_PREFIX=/usr")
      table.insert(t.flags, 2, "-DCMAKE_BUILD_TYPE=Release")
      table.insert(t.flags, 3, "-DCMAKE_SHARED_LIBS=True")
      table.insert(t.flags, 4, "-DCMAKE_GENERATOR=Ninja")

      -- allow databases to dynamically assign srcdir
      fp = io.open(t.flags[#t.flags])
      if fp then fp:close() else table.insert(t.flags, #t.flags, "..") end

      t.flags = table.concat(t.flags, ' ')
      status =
         os.execute(string.format("cmake %s", t.flags)) and
         setenv("DESTDIR", destdir) and
         os.execute"ninja install" and
         unsetenv"DESTDIR"
   end

   if t.build == "qmake" then
      t.flags = table.concat(t.flags, ' ')
      status =
         os.execute"qmake -makefile" and
         os.execute(string.format("$make %s", t.flags)) and
         os.execute"$make install DESTDIR=$destdir"
   end

   if t.build == "make" then
      t.flags = table.concat(t.flags, ' ')
      status =
         os.execute(string.format("$make %s", t.flags)) and
         os.execute(string.format("$make install DESTDIR=$destdir %s", t.flags))
   end

   if t.build == "meson" then
      table.insert(t.flags, 1, "-Dprefix=/usr")
      table.insert(t.flags, 2, "-Dlibdir=/usr/lib64")
      table.insert(t.flags, 3, "-Dsbindir=/usr/bin")
      table.insert(t.flags, 4, "-Dbuildtype=release")
      table.insert(t.flags, 5, "-Dwrap_mode=nodownload")
      t.flags = table.concat(t.flags, ' ')
      status =
         os.execute("meson setup build " .. t.flags) and
         setenv("DESTDIR", destdir) and
         os.execute"ninja -C build install" and
         unsetenv"DESTDIR"
   end

   if t.build == "python-build" then
      table.insert(t.flags, 1, "--destdir=$destdir")
      table.insert(t.flags, 2, "--no-compile-bytecode")
      t.flags = table.concat(t.flags, ' ')
      t.post = "mv $destdir/usr/lib $destdir/usr/lib64 2>/dev/null"
      status =
         os.execute"python3 -m build -nw || python3 -m flit_core.wheel" and
         os.execute(
            string.format("python3 -m installer %s dist/*.whl", t.flags))
   end

   if t.build == "cargo" then
      table.insert(t.flags, 1, "--root=$destdir/usr")
      table.insert(t.flags, 2, "--profile=release")
      table.insert(t.flags, 3, "--no-track")
      table.insert(t.flags, 4, "--locked")
      table.insert(t.flags, 5, "--path=.")
      t.flags = table.concat(t.flags, ' ')
      status =
         os.execute(string.format("cargo install %s", t.flags))
   end

   if t.build == "perl" then
      status =
         os.execute"perl Makefile.PL" and
         os.execute"$make" and
         os.execute"$make pure_install doc_install DESTDIR=$destdir"
   end

   if not status then
      error(string.format("error: build failed for %s", pkgname))
   end

   if t.post then os.execute(t.post) end

   -- touch all built files to SOURCE_DATE_EPOCH
   os.execute [[ find $destdir -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]

   -- cleanup
   unsetenv"destdir"; unsetenv"SOURCE_DATE_EPOCH"

   return makepkg(destdir)
end

function purge(pkgname) local fp, f
   f = string.format("/usr/okpkg/index/%s.index", pkgname)
   fp = io.open(f)
   if fp then
      for path in fp:lines() do os.remove(path:sub(2, #path)) end
      fp:close(); os.remove(f)
   end
end

function install(file) local v, fp, buf, pkgname
   v = vstr(file)

   -- install the tarball
   fp = io.popen(string.format("tar -C / -xvhf %s 2>&1", file))
   buf = fp:read('*a')
   fp:close()

   -- parse pkgname
   if #v > 0 then pkgname = basename(file:sub(1, #file-#v-8))
   else pkgname = basename(file:sub(1, #file-7)) end

   -- write the file index
   fp = io.open(string.format("/usr/okpkg/index/%s.index", pkgname), 'w')
   fp:write(buf)
   fp:close()

   -- let linker find new libraries
   os.execute"ldconfig"
end

function emerge(pkgname)
   download(pkgname); install(build(pkgname))
end

function chroot(path)
   ok.chroot(path)
end

-- main loop
while #arg > 1 do
   if arg[2]:sub(1,2) == "--" then load(arg[2]:sub(3,#arg[2]))()
   else _G[arg[1]](arg[2]) end
   table.remove(arg, 2)
end
