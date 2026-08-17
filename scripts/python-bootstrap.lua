#!/bin/lua

dofile("/bin/okpkg")
unpack = unpack or table.unpack
local ok = require("okutils")

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
