#!/usr/bin/env lua

dofile("/usr/bin/okpkg")

-- Imports 
local unpack = unpack or table.unpack
local C = unpack(loadfile("/etc/okpkg.conf")())
local ok = require("okutils")
local remove_all = ok.remove_all

-- Cleanup
remove_all("/usr/lib64/python3.14")
os.remove("/usr/bin/pyproject-build")
os.remove("/usr/bin/wheel")
os.remove("/usr/bin/meson")
os.remove("/usr/share/man/man1/meson.1")
os.remove("/usr/share/polkit-1/actions/com.mesonbuild.install.policy")

-- Bootstrap
purge("python3")
install(string.format("%s/python3-3.14.0-amd64.tar.lz", C["pkgdir"]))

purge("python-flit-core")
download("python-flit-core")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 bootstrap_install.py dist/*.whl")

purge("python-installer")
download("python-installer")
os.execute("python3 -m flit_core.wheel")
os.execute("cd src && python3 -m installer ../dist/*.whl")

purge("python-pyproject-hooks")
download("python-pyproject-hooks")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

purge("python-packaging")
download("python-packaging")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

purge("python-build")
download("python-build")
os.execute("python3 -m flit_core.wheel")
os.execute("python3 -m installer dist/*.whl")

purge("python-wheel")
download("python-wheel")
os.execute("python3 -m build -nx")
os.execute("python3 -m installer dist/*whl")

purge("python-setuptools")
download("python-setuptools")
os.execute("python3 -m build -nx")
os.execute("python3 -m installer dist/*whl")

purge("meson")
download("meson")
os.execute("python3 -m build -nx")
os.execute("python3 -m installer dist/*whl")
