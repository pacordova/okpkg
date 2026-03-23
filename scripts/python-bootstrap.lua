#!/usr/bin/env lua

-------------
-- Imports --
-------------
dofile("/usr/bin/okpkg")
local ok = require("okutils")
local unpack = unpack or table.unpack
local chdir = ok.chdir

-------------
-- Cleanup --
-------------
os.execute("rm -fr /usr/lib64/python3.14")
os.remove("/usr/bin/pyproject-build")
os.remove("/usr/bin/wheel")
purge("python3")
purge("python-flit-core")
purge("python-installer")
purge("python-pyproject-hooks")
purge("python-packaging")
purge("python-build")
purge("python-wheel")
purge("python-setuptools")

---------------
-- Bootstrap --
---------------
chdir(C["pkgdir"])
install("python3-3.14.0-amd64.tar.lz")

chdir(C["workdir"])
download("python-flit-core")
chdir("python-flit-core")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 bootstrap_install.py dist/*.whl")

chdir(C["workdir"])
download("python-installer")
chdir("python-installer")
os.execute("python3 -m flit_core.wheel")
chdir("src")
os.execute("python3 -m installer ../dist/*.whl")

chdir(C["workdir"])
download("python-pyproject-hooks")
chdir("python-pyproject-hooks")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

chdir(C["workdir"])
download("python-packaging")
chdir("python-packaging")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

chdir(C["workdir"])
download("python-build")
chdir("python-build")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

chdir(C["workdir"])
download("python-wheel")
chdir("python-wheel")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

chdir(C["workdir"])
download("python-setuptools")
chdir("python-setuptools")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")
