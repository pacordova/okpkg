#!/usr/bin/env lua

dofile("/usr/okpkg/okpkg.lua")
local ok = require("okutils")
local mkdir = ok.mkdir

local function download_all(db) 
   local fp, buf
   fp = io.open(db)
   buf = '\n'..fp:read("*a")
   fp:close()
   for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do download(i) end
end

os.execute("rm -fr /usr/okpkg/sources")
mkdir("/usr/okpkg/sources")

download_all("/usr/okpkg/db/system.db")
download_all("/usr/okpkg/db/modules.db")
download_all("/usr/okpkg/db/devel.db")
download_all("/usr/okpkg/db/lib.db")
download_all("/usr/okpkg/db/net.db")
download_all("/usr/okpkg/db/xorg.db")
download_all("/usr/okpkg/db/xfce.db")
--download_all("/usr/okpkg/db/binary.db")
download_all("/usr/okpkg/db/extra.db")
