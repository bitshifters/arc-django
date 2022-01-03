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
PNG2ARC_FONT=./bin/png2arc_font.py
PNG2ARC_SPRITE=./bin/png2arc_sprite.py
PNG2ARC_DEPS:=./bin/png2arc.py ./bin/arc.py ./bin/png2arc_font.py ./bin/png2arc_sprite.py
FOLDER=!Django01
HOSTFS=..\..\Arculator_V2.1_Windows/hostfs
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
	$(COPY) .\build\icon.bin "$(FOLDER)\!Sprites,ff9"

.PHONY:code
code: assets music
	$(MKDIR_P) "./build"
	$(VASM) -L compile.txt -m250 -Fbin -opt-adr -o build\arc-django.bin arc-django.asm

.PHONY:assets
assets: ./build/logo.lz4 ./build/logo.bin.pal ./build/scroller_font.bin \
	./build/note1.bin ./build/note2.bin ./build/note3.bin ./build/note4.bin \
	./build/note5.bin ./build/icon.bin

.PHONY:music
music: ./build/music_01.bin ./build/music_02.bin ./build/music_03.bin \
	./build/music_04.bin ./build/music_05.bin ./build/music_06.bin \
	./build/music_07.bin ./build/music_08.bin ./build/music_09.bin \
	./build/music_10.bin ./build/music_11.bin

##########################################################################
##########################################################################

.PHONY:clean
clean:
	$(RM_RF) "build"
	$(RM_RF) "$(FOLDER)"

##########################################################################
##########################################################################

# TODO: Figure out how to not need to make the build dir for every target.
./build/logo.lz4: ./build/logo.bin
./build/logo.bin: ./data/gfx/chipoDjango3.png $(PNG2ARC_DEPS)
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC) -o $@ -p $@.pal $< 9

./build/scroller_font.bin: ./data/font/font3.png $(PNG2ARC_DEPS)
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC_FONT) -o $@ --glyph-dim 16 16 --max-glyphs 59 $< 9

./build/note1.bin: ./data/gfx/note1.png ./build/logo.bin $(PNG2ARC_DEPS)
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC_FONT) -o $@ --glyph-dim 16 16 --max-glyphs 1 --use-palette ./build/logo.bin.pal --closest-match $< 9

./build/note2.bin: ./data/gfx/note2.png $(PNG2ARC_DEPS)
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC_FONT) -o $@ --glyph-dim 16 16 --max-glyphs 1 --use-palette ./build/logo.bin.pal --closest-match $< 9

./build/note3.bin: ./data/gfx/note3.png $(PNG2ARC_DEPS)
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC_FONT) -o $@ --glyph-dim 16 16 --max-glyphs 1 --use-palette ./build/logo.bin.pal --closest-match $< 9

./build/note4.bin: ./data/gfx/note4.png $(PNG2ARC_DEPS)
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC_FONT) -o $@ --glyph-dim 16 16 --max-glyphs 1 --use-palette ./build/logo.bin.pal --closest-match $< 9

./build/note5.bin: ./data/gfx/note5.png $(PNG2ARC_DEPS)
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC_FONT) -o $@ --glyph-dim 16 16 --max-glyphs 1 --use-palette ./build/logo.bin.pal --closest-match $< 9

./build/icon.bin: ./data/gfx/icon.png $(PNG2ARC_DEPS)
	$(MKDIR_P) "./build"
	$(PYTHON2) $(PNG2ARC_SPRITE) --name !django01 -o $@ $< 9

##########################################################################
##########################################################################

./build/music_01.bin: ./data/music/Juice-switchin-lanes.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_02.bin: ./data/music/bratgrumbeere.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_03.bin: ./data/music/mod.okeanos-red-drops_FIXED.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_04.bin: ./data/music/amiga-funeral.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_05.bin: ./data/music/dalezy-a-virag-elszaradt.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_06.bin: ./data/music/slash-paws-and-claws.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_07.bin: ./data/music/mod.vedder-resurgence.final.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_08.bin: ./data/music/curt-cool-quickshot_dramaking.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_09.bin: ./data/music/mod.okeanos-syncopated-groove.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_10.bin: ./data/music/Triace-Paula-at-the-Disco-final.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

./build/music_11.bin: ./data/music/mA2E-Concordia.mod
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
	$(LZ4) --best -f $< $@

# Rule to copy MOD files.
%.bin : %.mod
	$(MKDIR_P) "./build"
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

##########################################################################
##########################################################################
