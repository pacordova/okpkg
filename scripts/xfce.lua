#!/bin/lua

-- Bootstrap
os.execute("make -C /usr/okpkg install")

unpack = unpack or table.unpack

-- Imports
ok = require("okutils")
Dirs = dofile("/bin/okpkg")

local function build_all(x)
   local fp, buf
   fp = io.open(Dirs.tab .. "/" .. x)
   buf = fp:read("*a")
   fp:close()
   for i in buf:gmatch("\n?([%w%-_]*)%s*=%s*{.-}%s*;") do
      emerge(i)
      if i == "librsvg" or i == "gdk-pixbuf2" then
         os.execute("gdk-pixbuf-query-loaders --update-cache")
      end
   end
   ok.remove_all(Dirs.src)
   ok.create_directory(Dirs.src)
end

-- Env
ok.setenv("PATH", "/opt/cmake/bin:/opt/python3.13/bin:/opt/perl/bin:/bin")

-- Locale
os.execute("localedef -i POSIX -f ASCII      C           2>/dev/null ||:")
os.execute("localedef -i POSIX -f UTF-8      C.UTF-8     2>/dev/null ||:")
os.execute("localedef -i en_US -f ISO-8859-1 en_US       2>/dev/null ||:")
os.execute("localedef -i en_US -f UTF-8      en_US.UTF-8 2>/dev/null ||:")

emerge("sqlite")
emerge("python")
dofile("/usr/okpkg/scripts/python-bootstrap.lua")
emerge("libxml2")
emerge("libxslt")
dofile("/usr/okpkg/scripts/python-build.lua")
build_all("perl")
build_all("devel")
build_all("lib")
build_all("net")
build_all("xorg")
build_all("xfce")
build_all("video")

-- Set XFCE default terminal
local fp = io.open("/bin/xfce4-terminal", 'w')
fp:write([[
#!/bin/sh
/bin/st -e tmux new-session -A
]])
fp:close()
os.execute("chmod 755 /bin/xfce4-terminal")

-- Post-install
os.execute("sh /usr/okpkg/scripts/fix.sh")
