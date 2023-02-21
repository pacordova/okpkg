#!/usr/bin/env lua

fd = io.open("archive.db", "r")

local function strsplit(line)
    local split={}
    for word in string.gmatch(line, "[^%s]+") do
        table.insert(split, word)
    end
    return split
end

local function get_hash(shortkey)
    local url = io.open("url.db", "r")
    for line in url:lines() do
        if line:find(shortkey) then
            return strsplit(line)[1]
        end 
    end
    url:close()
end

local function get_url(shortkey)
    local url = io.open("url.db", "r")
    for line in url:lines() do
        if line:find(shortkey) then
            return strsplit(line)[2]
        end 
    end
    url:close()
end

local function print_table(name, tab)
    io.write(name.."={")
    io.write('hash="' .. tab["hash"] .. '",')
    io.write('url="' .. tab["url"] .. '",')
    io.write('build="' .. tab["build"] .. '",')

    local flags = tab["flags"]
    if flags ~= nil then
        io.write("flags={")
        for k,v in pairs(flags) do
            io.write('"' .. v .. '"' .. ",")
        end
        io.write("},")
    end

    io.write("}\n")
end

local function parse_line(line)
    if line == nil then return; end
    if line == "" then return; end

    local pkg = {}
    local cleanline = line:gsub("=[(]", " ")
    local cleanline = cleanline:gsub("[)]", "")
    local cleanline = strsplit(cleanline)

    local pkgname = cleanline[1]
    if pkgname == "#" then return; end

    local shortkey = cleanline[2]
    pkg["hash"] = get_hash(shortkey)
    pkg["url"] = get_url(shortkey)
    pkg["build"] = cleanline[3]
    local flags = {}
    if #cleanline > 3 then
       for i=4, #cleanline do
            table.insert(flags, cleanline[i])
       end
    end
    if #flags > 0 then
        pkg["flags"] = flags
    end

    print_table(pkgname, pkg)
end

for line in fd:lines() do
    parse_line(line)
end

fd:close()
