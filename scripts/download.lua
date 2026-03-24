#!/usr/bin/env lua

dofile("/usr/bin/okpkg")

local unpack = unpack or table.unpack
local C = unpack(loadfile("/etc/okpkg.conf")())
local ok = require("okutils")
local chdir, mkdir, remove_all = 
   ok.chdir, ok.mkdir, ok.remove_all

local function download_all(x)
   local fp, buf
   fp = io.open(string.format("%s/db/%s", C["okdir"], x))
   buf = '\n'..fp:read("*a")
   fp:close()
   for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
      download(i)
      chdir(C["workdir"])
      remove_all(i)
   end
end

remove_all(C["workdir"])
mkdir(C["workdir"])

download_all("base")
download_all("python")
download_all("perl")
download_all("devel")
download_all("lib")
download_all("net")
download_all("fonts")
download_all("xorg")
download_all("gtk")
download_all("xfce")
download_all("video")
download_all("flatpak")
