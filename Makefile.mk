ifeq ($(OS),Windows_NT)
RM_RF:=-cmd /c rd /s /q
MKDIR_P:=-cmd /c mkdir
COPY:=copy
VASM?=bin\vasmarm_std_win32.exe
LZ4?=bin\lz4.exe
PYTHON2?=C:\Dev\Python27\python.exe
PYTHON3?=python.exe
else
RM_RF:=rm -Rf
MKDIR_P:=mkdir -p
COPY:=cp
VASM?=vasmarm_std
LZ4?=lz4
PYTHON3?=python
endif

PNG2ARC=./bin/png2arc.py
PNG2BBC_DEPS:=./bin/png2arc.py ./bin/arc.py
FOLDER=!Django01
HOSTFS=..\..\Arculator_V2.0_Windows/hostfs
# TODO: Need a copy command that copes with forward slash directory separator.

##########################################################################
##########################################################################

.PHONY:deploy
deploy:folder
	$(RM_RF) "$(HOSTFS)\$(FOLDER)"
	$(MKDIR_P) "$(HOSTFS)\$(FOLDER)"
	$(COPY) "$(FOLDER)\*.*" "$(HOSTFS)\$(FOLDER)\*.*"

.PHONY:folder
folder: code music
	$(RM_RF) $(FOLDER)
	$(MKDIR_P) $(FOLDER)
	$(COPY) .\folder\*.* "$(FOLDER)\*.*"
	$(COPY) .\build\arc-django.bin "$(FOLDER)\!RunImage,ff8"
	$(COPY) .\build\music_01.bin "$(FOLDER)\Music,001"

.PHONY:code
code: assets
	$(MKDIR_P) "./build"
	$(VASM) -L compile.txt -m250 -Fbin -opt-adr -o build\arc-django.bin arc-django.asm

.PHONY:assets
assets: ./build/logo.lz4 ./build/logo.bin.pal

.PHONY:music
music: ./build/music_01.bin

##########################################################################
##########################################################################

.PHONY:clean
clean:
	$(RM_RF) "build"
	$(RM_RF) "$(FOLDER)"

##########################################################################
##########################################################################

./build/logo.lz4: ./build/logo.bin
./build/logo.bin: ./data/gfx/logo_320x98.png
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC) -o $@ -p $@.pal $< 9 --x2

##########################################################################
##########################################################################

./build/music_01.bin: ./data/music/4mat-l-f-f.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

##########################################################################
##########################################################################

# Rule to convert PNG files, assumes MODE 9.
%.bin : %.png $(PNG2ARC_DEPS)
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC) -o $@ -p $@.pal $< 9

# Rule to LZ4 compress bin files.
%.lz4 : %.bin
	$(MKDIR_P) "./build"
	$(LZ4) -f $< $@

# Rule to copy MOD files.
%.bin : %.mod
	$(MKDIR_P) "./build"
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

##########################################################################
##########################################################################
