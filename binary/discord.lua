#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

local ok = require"okutils"
mkdir, chdir, symlink = 
   ok.mkdir, ok.chdir, ok.symlink

-- vars
pkgname = "discord-bin"
--url = "https://dl.discordapp.net/apps/linux/0.0.39/discord-0.0.39.tar.gz"
url = "https://discord.com/api/download?platform=linux&format=tar.gz"

-- download
chdir("/usr/okpkg/packages")
mkdir(pkgname)
chdir(pkgname)
os.execute("curl -L '" .. url .. "' | tar -xzf -")

-- prepare package
mkdir("usr")
mkdir("usr/lib64")
mkdir("usr/bin")
mkdir("usr/share")
mkdir("usr/share/applications")
mkdir("usr/share/icons")

-- copy old desktop file
fp = io.open("Discord/discord.desktop")
buf = fp:read("*a")
fp:close()

-- modify desktop file
fp = io.open("Discord/discord.desktop", "w")
fp:write(buf:gsub("Exec=.-\n", "Exec=/usr/bin/discord\n"))
fp:close()

os.rename("Discord/discord.desktop", "usr/share/applications/discord.desktop")
os.rename("Discord/discord.png", "usr/share/icons/discord.png")
os.rename("Discord", "usr/lib64/discord")
symlink("/usr/lib64/discord/Discord", "usr/bin/discord")

-- install
chdir("..")
install(makepkg(pkgname))
