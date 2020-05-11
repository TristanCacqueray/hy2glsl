#!/usr/bin/env python
# Copyright 2019 tristanC
# This file is part of hy2glsl.
#
# Hy2glsl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Hy2glsl is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Hy2glsl.  If not, see <https://www.gnu.org/licenses/>.

from setuptools import find_packages, setup

setup(
    name="hy2glsl",
    version="0.0.2",
    install_requires=['hy'],
    packages=find_packages(exclude=['tests']),
    package_data={
        'hy2glsl': ['*.hy'],
    },
    author="Tristan de Cacqueray",
    author_email="tristanC@wombatt.eu",
    long_description=open("README.md").read(),
    long_description_content_type='text/markdown',
    license="GPL-3",
    url="https://github.com/TristanCacqueray/hy2glsl",
    platforms=['any'],
    python_requires='>=3.4',
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: DFSG approved",
        "License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)",
        "Operating System :: OS Independent",
        "Programming Language :: Lisp",
        "Topic :: Software Development :: Libraries",
    ]
)
