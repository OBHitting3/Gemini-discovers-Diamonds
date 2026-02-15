# -*- mode: python ; coding: utf-8 -*-
"""PyInstaller spec for building Iron Forge as a standalone executable.

Usage:
    pip install pyinstaller
    pyinstaller ironforge.spec

This produces a single-file executable in dist/ironforge (or dist/ironforge.exe on Windows).
"""

import sys
from pathlib import Path

block_cipher = None

a = Analysis(
    ["src/ironforge/__main__.py"],
    pathex=["src"],
    binaries=[],
    datas=[],
    hiddenimports=[
        "ironforge",
        "ironforge.cli",
        "ironforge.commands",
        "ironforge.commands.init",
        "ironforge.commands.build",
        "ironforge.commands.clean",
        "ironforge.commands.config_cmd",
        "ironforge.commands.status",
        "ironforge.commands.version",
        "ironforge.core",
        "ironforge.core.config",
        "ironforge.core.engine",
        "ironforge.utils",
        "ironforge.utils.errors",
        "ironforge.utils.logging",
        "ironforge.utils.output",
        "click",
        "rich",
        "pydantic",
        "tomli_w",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="ironforge",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
