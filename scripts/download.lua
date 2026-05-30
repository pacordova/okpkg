#!/bin/lua

local unpack = unpack or table.unpack
local ok = require("okutils")

local Dirs = dofile("/bin/okpkg")

local function download_all(x)
   local fp, buf
   fp = io.open(string.format("%s/%s", Dirs.tab, x))
   buf = '\n'..fp:read("*a")
   fp:close()
   for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
      download(i)
      ok.chdir(Dirs.src)
      ok.remove_all(i)
   end
end

ok.remove_all(Dirs.src)
ok.mkdir(Dirs.src)

download_all("sys")
download_all("python")
download_all("perl")
download_all("devel")
download_all("lib")
download_all("net")
--download_all("fonts")
--download_all("xorg")
--download_all("gtk")
--download_all("xfce")
--download_all("video")
--download_all("flatpak")
