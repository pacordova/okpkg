#!/usr/bin/env lua

local ok = require"okutils"

local chdir, mkdir, symlink, setenv, unsetenv =
    ok.chdir, ok.mkdir, ok.symlink, ok.setenv, ok.unsetenv

local fp, url

-- website gives us a bz2
url = "https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US"

-- prepare package
mkdir"/usr"
mkdir"/usr/lib64"
mkdir"/usr/lib64/firefox"
mkdir"/usr/bin"
mkdir"/usr/share"
mkdir"/usr/share/applications"
os.execute("curl -L '" .. url .. "' | tar -C /usr/lib64 -xjf -")

fp = io.open"/usr/bin/firefox"
if not fp then
fp = io.open("/usr/bin/firefox", 'w')
fp:write [[
#!/bin/sh
/usr/bin/apulse /usr/lib64/firefox/firefox
]]
fp:close()
os.execute"chmod +x /usr/bin/firefox"
else fp:close() end

fp = io.open"/usr/share/applications/firefox.desktop"
if not fp then
fp = io.open("/usr/share/applications/firefox.desktop", 'w')
fp:write [[
[Desktop Entry]
Encoding=UTF-8
Name=Firefox Developer Edition
GenericName=Web Browser
Exec=firefox %u
Terminal=false
Type=Application
Icon=firefox-developer-edition
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=text/xml;text/mml;text/html;application/xhtml+xml;application/vnd.mozilla.xul+xml;x-scheme-handler/http;x-scheme-handler/https
StartupNotify=True
]]
fp:close()
else fp:close() end

-- copy icons
chdir"/usr/lib64/firefox/browser/chrome/icons/default"
setenv("destdir", "/usr/share/icons/hicolor")
os.execute [[
   cp -p default128.png $destdir/128x128/apps/firefox-developer-edition.png
   cp -p default16.png  $destdir/16x16/apps/firefox-developer-edition.png
   cp -p default32.png  $destdir/32x32/apps/firefox-developer-edition.png
   cp -p default48.png  $destdir/48x48/apps/firefox-developer-edition.png
   cp -p default64.png  $destdir/64x64/apps/firefox-developer-edition.png
]]
unsetenv("destdir")
