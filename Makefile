# Wrapper so that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# The real build is Makefile.mk, run by bin\snmake.exe via make.bat.
.PHONY: all build deploy help
all: build

build:
	cmd /c .\make.bat folder

deploy:
	cmd /c .\make.bat deploy

help:
	@echo make         - build the !Django01 RISC OS folder in the repo (make.bat folder)
	@echo make deploy  - build and copy !Django01 to ..\arculator\hostfs\Builds (make.bat's default)
	@echo make help    - this list
