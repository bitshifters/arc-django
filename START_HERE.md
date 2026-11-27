# arc-django: start here

An Acorn Archimedes port of the Chipo Django musicdisk (Rabenauge, Deadline 2021): ARM assembler (vasm), QTM music player and RasterMan, released January 2022.

| | |
|---|---|
| GitHub | https://github.com/bitshifters/arc-django (public; transferred from kieranhj/arc-django on 2026-11-27, old URL redirects) |
| Upstream | port of the Amiga musicdisk by Rabenauge (assets in `from_bodo/`, `data/`) |
| Local path | D:\bitshifters\arc-django (moved from D:\archie\mine on 2026-11-27; before that OneDrive\Archie\Repos) |
| Branch | main; other branches: rasterman (same commit as main), autoplay-no-rasterman (3 commits not in main, 2022-01-03), wip/2026-11-tidy |
| Last commit | 2022-01-18: Remove individual build targets. |

## What's in here

- `arc-django.asm` entry, `src/`, `lib/`; `data/` (gfx, fonts, music), `from_bodo/` (original assets).
- `folder/` (QTM, RasterMan, MemAlloc modules copied into the app), `bin/` tools.
- `Makefile.mk` (real build, via `make.bat` / `bin\snmake.exe`), `compile.txt`, `loader.txt`, `arc-django.code-workspace`.

## Build and run

- `make`: builds the `!Django01` folder in the repo (`make.bat folder`). Works (2026-11-22), using converted assets already in `build\`.
- `make deploy`: make.bat's default, also copies `!Django01` to the hostfs; `make help`.
- Asset conversion: the `bin\*.py` converters were ported to Python 3 on 2026-11-22 and give byte-identical output. `make.bat` sets `PYTHON2=py -3` unless already set, because `Makefile.mk` (which has an uncommitted local edit) still defaults `PYTHON2` to `C:\Dev\Python27\python.exe`.
- Run `!Django01` in Arculator (`D:\archie\mine\arculator`).

## Local changes

- Uncommitted: `Makefile.mk` (HOSTFS changed from `..\..\Arculator_V2.1_Windows/hostfs` to `..\arculator/hostfs`) and a one-line change in `arc-django.asm`.
- `wip/2026-11-tidy` (pushed): snapshot of those two edits.

## Status and next steps

- Released; finished. Nothing planned.

## See also

- `README.md`; `D:\bitshifters\arc-django-2` (the sequel), `D:\archie\mine\archie-verse` (Chipo Django 3 on branch wip/chipo-django3).
