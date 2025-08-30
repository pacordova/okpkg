#!/usr/bin/env lua

local ok = require("okutils")
local chdir, mkdir = ok.chdir, ok.mkdir
local dbpath = "/var/lib/okpkg/db"
local srcpath = "/var/lib/okpkg/sources"

dofile("/usr/bin/okpkg")

local function download_all(db) 
   local fp, buf
   fp = io.open(string.format("%s/%s", dbpath, db))
   buf = '\n'..fp:read("*a")
   fp:close()
   for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do 
      download(i) 
      chdir(srcpath)
      os.execute(string.format("rm -fr %s/%s", srcpath, i))
   end
end

os.execute("rm -fr " .. srcpath)
mkdir(srcpath)

download_all("system.db")
download_all("python.db")
download_all("perl.db")
download_all("devel.db")
download_all("lib.db")
download_all("net.db")
download_all("fonts.db")
download_all("xorg.db")
download_all("gtk.db")
download_all("xfce.db")
download_all("video.db")
download_all("flatpak.db")
