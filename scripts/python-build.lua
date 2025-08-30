#!/usr/bin/env lua

dofile("python-bootstrap")

local dbpath = "/var/lib/okpkg/db/python.db"

local fp, buf
fp = io.open(dbpath)
buf = '\n' .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do 
   if i ~= "python3" then purge(i); emerge(i) end
end
