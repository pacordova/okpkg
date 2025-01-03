#!/bin/bash

rm -fr "/usr/lib64/python3"*
okpkg purge python3
okpkg emerge python3 
okpkg emerge python-{flit-core,installer,pyproject-hooks,packaging,build,wheel,setuptools}
okpkg emerge python-{markupsafe,jinja,docutils,mako,editables,typing_extensions,setuptools-scm}
okpkg emerge python-{pluggy,pathspec,calver,trove-classifiers,hatchling,pygments,libevdev,pyudev,ply}
okpkg emerge glad python-pyparsing cython pyyaml meson libxml2 xcb-proto gobject-introspection glib2
