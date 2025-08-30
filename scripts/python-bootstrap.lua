#!/usr/bin/env lua

-------------
-- Imports --
-------------
dofile("/usr/bin/okpkg")
local ok = require("okutils")
local unpack = unpack or table.unpack
local chdir = ok.chdir
local srcdir = "/var/lib/okpkg/sources"

-------------
-- Cleanup --
-------------
os.execute("rm -fr /usr/lib64/python3.13")
os.remove("/usr/bin/pyproject-build")
os.remove("/usr/bin/wheel")
install("/var/lib/okpkg/packages/a/python3-3.13.7-amd64.tar.lz")

---------------
-- Bootstrap --
---------------
chdir(srcdir)
download("python-flit-core")
chdir("python-flit-core")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 bootstrap_install.py dist/*.whl")

chdir(srcdir)
download("python-installer")
chdir("python-installer")
os.execute("python3 -m flit_core.wheel")
chdir("src")
os.execute("python3 -m installer ../dist/*.whl")

chdir(srcdir)
download("python-pyproject-hooks")
chdir("python-pyproject-hooks")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

chdir(srcdir)
download("python-packaging")
chdir("python-packaging")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

chdir(srcdir)
download("python-build")
chdir("python-build")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

chdir(srcdir)
download("python-wheel")
chdir("python-wheel")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

chdir(srcdir)
download("python-setuptools")
chdir("python-setuptools")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")
