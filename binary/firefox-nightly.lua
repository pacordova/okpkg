#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- vars
pkgname = "firefox"
url = "https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64&lang=en-US"

-- website gives us a bz2
chdir("/usr/okpkg/packages")
mkdir(pkgname)
os.execute("curl -L '" .. url .. "' | tar -C " .. pkgname .. " -xjf -")

-- prepare package
chdir(pkgname)
mkdir("/usr")
mkdir("/usr/lib64")
mkdir("/usr/lib64/firefox")
mkdir("/usr/bin")
mkdir("/usr/share")
mkdir("/usr/share/applications")
os.execute("rsync -Pr firefox/ /usr/lib64/firefox && pkill firefox")
symlink("/usr/lib64/firefox/firefox", "/usr/bin/firefox")
--mkdir("./usr/share/pixmaps")
--symlink("/usr/lib64/firefox/browser/chrome/icons/default/default128.png", "usr/share/pixmaps/firefox.png")

fp = io.open("/usr/share/applications/firefox.desktop", 'w')
fp:write [[
[Desktop Entry]
Encoding=UTF-8
Name=Firefox Nightly
GenericName=Web Browser
Exec=firefox %u
Terminal=false
Type=Application
Icon=firefox-nightly
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=text/xml;text/mml;text/html;application/xhtml+xml;application/vnd.mozilla.xul+xml;x-scheme-handler/http;x-scheme-handler/https
StartupNotify=True
]]
fp:close()

-- install
--chdir("..")
--install(makepkg(pkgname))
