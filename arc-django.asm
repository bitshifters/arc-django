; ============================================================================
; arc-django - An Archimedes port of Chipo Django musicdisk by Rabenauge
; ============================================================================

.equ _DEBUG, 1
.equ _FIX_FRAME_RATE, 0					; useful for !DDT breakpoints
.equ _DEBUG_RASTERS, (_DEBUG && 0)

.equ Screen_Banks, 1
.equ Screen_Mode, 9
.equ Screen_Width, 320
.equ Screen_Height, 256
.equ Mode_Height, 256
.equ Screen_PixelsPerByte, 2
.equ Screen_Stride, Screen_Width/Screen_PixelsPerByte
.equ Screen_Bytes, Screen_Stride*Screen_Height
.equ Mode_Bytes, Screen_Stride*Mode_Height

.equ Scroller_Y_Pos, 237

.equ VU_Bars_Y_Pos, 216
.equ VU_Bars_Height, 3
.equ VU_Bars_Gap, 4
.equ VU_Bars_Effect, 2	; 'effect'
.equ VU_Bars_Gravity, 1	; lines per vsync

.equ Horizontal_Divider_1, 98
.equ Horizontal_Divider_2, 202
.equ Horizontal_Divider_3, 233

.equ Mouse_Sensitivity, 10
.equ Glitch_Time, 12

.include "lib/swis.h.asm"

; ============================================================================
; App defines
; ============================================================================

.equ MAX_SONGS, 11

.org 0x8000

; ============================================================================
; Stack
; ============================================================================

Start:
    adrl sp, stack_base
	B main

.skip 1024
stack_base:

; ============================================================================
; Main
; ============================================================================

main:
	MOV r0,#22	;Set MODE
	SWI OS_WriteC
	MOV r0,#Screen_Mode
	SWI OS_WriteC

	; Set screen size for number of buffers
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	MOV r0, #DynArea_Screen
	MOV r2, #Mode_Bytes * Screen_Banks
	SUBS r1, r2, r1
	SWI OS_ChangeDynamicArea
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	CMP r1, #Mode_Bytes * Screen_Banks
	ADRCC r0, error_noscreenmem
	SWICC OS_GenerateError

	; Disable cursor
	adr r0, vdu_disable_cursor
	mov r1, #8
	swi OS_WriteN

	; Seed RND.
	swi OS_ReadMonotonicTime
	str r0, rnd_seed

	; EARLY INIT / LOAD STUFF HERE!
	; Setting sample quality to maximum makes the tunes sound much worse!
	; QTM default is 32us, but 48us sounds correct. I presume this is
	; because chiptune samples are so small they cannot be interpolated
	; in any meaningful way.
	mov r0, #48
	swi QTM_SetSampleSpeed

	mov r0, #VU_Bars_Effect
	mov r1, #VU_Bars_Gravity
	swi QTM_VUBarControl

	; Clear all screen buffers
	mov r1, #1
.1:
	str r1, scr_bank

	; CLS bank N
	mov r0, #OSByte_WriteVDUBank
	swi OS_Byte
	mov r0, #12
	SWI OS_WriteC

	ldr r1, scr_bank
	add r1, r1, #1
	cmp r1, #Screen_Banks
	ble .1

	; Start with bank 1
	mov r1, #1
	str r1, scr_bank
	
	; Claim the Error vector
	MOV r0, #ErrorV
	ADR r1, error_handler
	MOV r2, #0
	SWI OS_Claim

	; Claim the Event vector
	mov r0, #EventV
	adr r1, event_handler
	mov r2, #0
	swi OS_AddToVector

	; LATE INITALISATION HERE!

	adrl r2, logo_pal_block
	bl palette_set_block

	bl get_screen_addr
	ldr r12, screen_addr
	adrl r9, logo_data
	bl plot_logo

	; Draw menu to screen.
	bl plot_dividers
	bl plot_menu

	; Start with song #0.
	mov r0, #0
	bl play_song

	; Enable Vsync event
	mov r0, #OSByte_EventEnable
	mov r1, #Event_VSync
	SWI OS_Byte

main_loop:

	; Block if we've not even had a vsync since last time - we're >50Hz!
	ldr r1, last_vsync
.1:
	ldr r2, vsync_count
	cmp r1, r2
	beq .1
	.if _FIX_FRAME_RATE
	mov r0, #1
	.else
	sub r0, r2, r1
	.endif
	str r2, last_vsync
	str r0, vsync_delta

	; R0 = vsync delta since last frame.

	; show debug
	.if _DEBUG
	bl debug_write_vsync_count
	.endif

	; DO STUFF HERE!
	bl get_next_screen_for_writing
	ldr r8, screen_addr
	bl show_screen_at_vsync

	; scroll the bottom.
	bl scroller_update

	; do VU bars.
	bl update_vu_bars

	; do glitch.
	ldr r0, glitch_timer
	cmp r0, #0
	beq .8

	subs r0, r0, #1
	str r0, glitch_timer

	ldr r12, screen_addr
	adrl r9, logo_data
	bleq plot_logo
	blne plot_logo_glitched
	.8:

	.if _DEBUG_RASTERS
	adr r0, vdu_set_border_green
	mov r1, #6
	swi OS_WriteN
	.endif
	bl update_sprites
	.if _DEBUG_RASTERS
	adr r0, vdu_set_border_black
	mov r1, #6
	swi OS_WriteN
	.endif

	bl keyboard_scan_debounced

	; exit if Escape is pressed
	mov r1, #IKey_Escape
	bl check_key
	beq exit

	; check up
	mov r1, #IKey_ArrowUp
	bl check_key_debounced
	bne .2

	ldr r3, selection_number
	cmp r3, #0
	beq .2
	bl plot_menu_item
	sub r3, r3, #1
	str r3, selection_number
	
.2:
	; check down
	mov r1, #IKey_ArrowDown
	bl check_key_debounced
	bne .3

	ldr r3, selection_number
	cmp r3, #MAX_SONGS-1
	bge .3
	bl plot_menu_item
	add r3, r3, #1
	str r3, selection_number

.3:
	; check return
	mov r1, #IKey_Return
	bl check_key_debounced
	beq .4

	mov r1, #IKey_LeftClick
	bl check_key_debounced
	bne .5

	.4:
	ldr r3, song_number
	ldr r0, selection_number
	bl play_song
	bl plot_menu_item

.5:
	; Check mouse.
	swi OS_Mouse
	ldr r0, prev_mouse_y
	str r1, prev_mouse_y
	subs r0, r0, r1
	; R0=mouse delta
	cmp r0, #Mouse_Sensitivity
	blt .6

	; TODO: Dedupe code.
	ldr r3, selection_number
	cmp r3, #MAX_SONGS-1
	bge .6
	bl plot_menu_item
	add r3, r3, #1
	str r3, selection_number

.6:
	cmp r0, #-Mouse_Sensitivity
	bgt .7

	; TODO: Dedupe code.
	ldr r3, selection_number
	cmp r3, #0
	beq .7
	bl plot_menu_item
	sub r3, r3, #1
	str r3, selection_number

.7:
	str r0, mouse_delta_y

	; Update selected item.
	mov r0, #17	; set text colour
	swi OS_WriteC
	ldr r0, selection_colour
	add r0, r0, #1
	cmp r0, #15
	movgt r0, #0
	str r0, selection_colour
	swi OS_WriteC
	ldr r3, selection_number
	bl plot_menu_item_ex

	b main_loop

keyboard_scan_debounced:
	mov r0, #OSByte_KeyboardScan
	mov r1, #1
	swi OS_Byte
	; R1 contains key or 0xff if no key.
	mov r2, r1	; key pressed
	ldr r0, held_key
	cmp r1, r0
	moveq r2, #0xff
	str r1, held_key
	str r2, current_key
	mov pc, lr

; R1=IKey no. EOR 0xff
check_key_debounced:
	eor r1, r1, #0xff
	ldr r0, current_key
	cmp r0, r1
	mov pc, lr

; R1=IKey no.
check_key:
	mov r0, #OSByte_ReadKey
	mov r2, #0xff
	swi OS_Byte
	cmp r1, #0xff
	cmpeq r2, #0xff
	mov pc, lr

current_key:
	.long 0

held_key:
	.long 0

prev_mouse_y:
	.long 0

mouse_delta_y:
	.long 0

song_number:
	.long -1

selection_number:
	.long 0

selection_colour:
	.long 0

glitch_timer:
	.long 0

error_noscreenmem:
	.long 0
	.byte "Cannot allocate screen memory!"
	.align 4
	.long 0

.if _DEBUG
debug_print_r0:
	stmfd sp!, {r0-r2}
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex4
	adr r0, debug_string
	swi OS_WriteO
	ldmfd sp!, {r0-r2}
	mov pc, lr

debug_write_vsync_count:
	str lr, [sp, #-4]!
	mov r0, #30	; home cursor
	swi OS_WriteC
	mov r0, #17	; set text colour
	swi OS_WriteC
	mov r0, #15
	swi OS_WriteC

    ; display current tracker position
    mov r0, #-1
    mov r1, #-1
    swi QTM_Pos

	mov r3, r1
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex2
	adr r0, debug_string
	swi OS_WriteO

	mov r0, r3
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex2
	adr r0, debug_string
	swi OS_WriteO

	swi OS_NewLine
	ldr r0, song_number
	bl debug_print_r0

	mov r0, #32
	swi OS_WriteC
	ldr r0, selection_number
	bl debug_print_r0

	mov r0, #32
	swi OS_WriteC
	ldr r0, prev_mouse_y
	bl debug_print_r0

.if 0
	; display frame count / frame rate etc.
	ldr r0, vsync_count	; vsync_delta
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex4

	adr r0, debug_string
	swi OS_WriteO
.endif
	ldr pc, [sp], #4

debug_string:
	.skip 8
.endif

get_screen_addr:
	str lr, [sp, #-4]!
	adrl r0, screen_addr_input
	adrl r1, screen_addr
	swi OS_ReadVduVariables
	ldr pc, [sp], #4
	
screen_addr_input:
	.long VD_ScreenStart, -1

exit:	
	; wait for vsync (any pending buffers)
	mov r0, #19
	swi OS_Byte

	; disable music
	mov r0, #0
	swi QTM_Stop

	; disable vsync event
	mov r0, #OSByte_EventDisable
	mov r1, #Event_VSync
	swi OS_Byte

	; release our event handler
	mov r0, #EventV
	adr r1, event_handler
	mov r2, #0
	swi OS_Release

	; release our error handler
	mov r0, #ErrorV
	adr r1, error_handler
	mov r2, #0
	swi OS_Release

	; Display whichever bank we've just written to
	mov r0, #OSByte_WriteDisplayBank
	ldr r1, scr_bank
	swi OS_Byte
	; and write to it
	mov r0, #OSByte_WriteVDUBank
	ldr r1, scr_bank
	swi OS_Byte

	SWI OS_Exit

; R0=event number
event_handler:
	cmp r0, #Event_VSync
	movnes pc, r14

	STMDB sp!, {r0-r1, lr}

	; update the vsync counter
	LDR r0, vsync_count
	ADD r0, r0, #1
	STR r0, vsync_count

	; is there a new screen buffer ready to display?
	LDR r1, buffer_pending
	CMP r1, #0
	LDMEQIA sp!, {r0-r1, pc}

	; set the display buffer
	MOV r0, #0
	STR r0, buffer_pending
	MOV r0, #OSByte_WriteDisplayBank

	; some SVC stuff I don't understand :)
	STMDB sp!, {r2-r12}
	MOV r9, pc     ;Save old mode
	ORR r8, r9, #3 ;SVC mode
	TEQP r8, #0
	MOV r0,r0
	STR lr, [sp, #-4]!
	SWI XOS_Byte

	; set full palette if there is a pending palette block
	ldr r2, palette_pending
	cmp r2, #0
	beq .4

    adr r1, palette_osword_block
    mov r0, #16
    strb r0, [r1, #1]       ; physical colour

    mov r3, #0
    .3:
    strb r3, [r1, #0]       ; logical colour

    ldr r4, [r2], #4        ; rgbx
    and r0, r4, #0xff
    strb r0, [r1, #2]       ; red
    mov r0, r4, lsr #8
    strb r0, [r1, #3]       ; green
    mov r0, r4, lsr #16
    strb r0, [r1, #4]       ; blue
    mov r0, #12
    swi XOS_Word

    add r3, r3, #1
    cmp r3, #16
    blt .3

	mov r0, #0
	str r0, palette_pending
.4:

	LDR lr, [sp], #4
	TEQP r9, #0    ;Restore old mode
	MOV r0, r0
	LDMIA sp!, {r2-r12}
	LDMIA sp!, {r0-r1, pc}

; TODO: rename these to be clearer.
scr_bank:
	.long 0				; current VIDC screen bank being written to.

palette_block_addr:
	.long 0				; (optional) ptr to a block of palette data for the screen bank being written to.

vsync_count:
	.long 0				; current vsync count from start of exe.

last_vsync:
	.long 0				; vsync count at start of previous frame.

vsync_delta:
	.long 0

buffer_pending:
	.long 0				; screen bank number to display at vsync.

palette_pending:
	.long 0				; (optional) ptr to a block of palette data to set at vsync.

error_handler:
	STMDB sp!, {r0-r2, lr}
	MOV r0, #OSByte_EventDisable
	MOV r1, #Event_VSync
	SWI OS_Byte
	MOV r0, #EventV
	ADR r1, event_handler
	mov r2, #0
	SWI OS_Release
	MOV r0, #ErrorV
	ADR r1, error_handler
	MOV r2, #0
	SWI OS_Release
	MOV r0, #OSByte_WriteDisplayBank
	LDR r1, scr_bank
	SWI OS_Byte
	LDMIA sp!, {r0-r2, lr}
	MOVS pc, lr

show_screen_at_vsync:
	; Show current bank at next vsync
	ldr r1, scr_bank
	str r1, buffer_pending
	; Including its associated palette
	ldr r1, palette_block_addr
	str r1, palette_pending
	mov pc, lr

get_next_screen_for_writing:
	; Increment to next bank for writing
	ldr r1, scr_bank
	add r1, r1, #1
	cmp r1, #Screen_Banks
	movgt r1, #1
	str r1, scr_bank

	; Now set the screen bank to write to
	mov r0, #OSByte_WriteVDUBank
	swi OS_Byte

	; Back buffer address for writing bank stored at screen_addr
	b get_screen_addr

play_song:
	swi QTM_Stop
	; Unload the current module.
	mov r1, r0
	mov r0, #-1
	swi QTM_Clear
	mov r0, r1

	; Load module.
	str r0, song_number
	adr r2, music_table
	ldr r1, [r2, r0, lsl #2]	; r0 * 4
	add r1, r1, r2				; MOD data address
	mov r0, #0					; load from address
	swi QTM_Load

	; Play music!
	swi QTM_Start

	mov r0, #Glitch_Time
	str r0, glitch_timer
	mov pc, lr

plot_menu:
	str lr, [sp, #-4]!
	mov r3, #MAX_SONGS
	.1:
	bl plot_menu_item
	subs r3, r3, #1
	bpl .1
	ldr pc, [sp], #4

; R3=item # (preserved)
plot_menu_item:
	mov r0, #0
	ldr r1, song_number
	cmp r3, r1
	moveq r0, #SmallFont_BoldBase
	str r0, small_font_bold_flag
; Fall through!
plot_menu_item_ex:
	str lr, [sp, #-4]!
	adr r2, menu_table
	ldr r1, [r2, r3, lsl #2]	; r0 * 4
	add r0, r1, r2				; string address
	bl small_font_plot_string
	ldr pc, [sp], #4

; ============================================================================
; VU bars
; ============================================================================

update_vu_bars:
	str lr, [sp, #-4]!
	mov r0, #0
	swi QTM_ReadVULevels
	; R0 = word containing 1 byte per channel 1-4 VU bar heights 0-64

	ldr r12, screen_addr

	and r10, r0, #0xff
	mov r11, #VU_Bars_Y_Pos
	bl plot_vu_bar

	mov r10, r0, lsr #8
	and r10, r10, #0xff
	mov r11, #VU_Bars_Y_Pos + 1 * VU_Bars_Gap
	bl plot_vu_bar

	mov r10, r0, lsr #16
	and r10, r10, #0xff
	mov r11, #VU_Bars_Y_Pos + 2 * VU_Bars_Gap
	bl plot_vu_bar

	mov r10, r0, lsr #24
	mov r11, #VU_Bars_Y_Pos + 3 * VU_Bars_Gap
	bl plot_vu_bar

	; Some fake bars to blank the sprites.
	mov r10, #0
	mov r11, #VU_Bars_Y_Pos - 2 * VU_Bars_Gap
	bl plot_vu_bar

	mov r10, #0
	mov r11, #VU_Bars_Y_Pos - 1 * VU_Bars_Gap
	bl plot_vu_bar

	ldr pc, [sp], #4

; TODO: Feels like duped code here.
plot_dividers:
	str lr, [sp, #-4]!

	mov r1, #-1
	mov r2, r1
	mov r3, r1
	mov r4, r1
	mov r5, r1
	mov r6, r1
	mov r7, r1
	mov r8, r1

	ldr r12, screen_addr

	mov r0, #Horizontal_Divider_1
	add r9, r12, r0, lsl #7	; y*128
	add r9, r9, r0, lsl #5	; +y*32 = y*160
	bl plot_horizontal_line

	mov r0, #Horizontal_Divider_2
	add r9, r12, r0, lsl #7	; y*128
	add r9, r9, r0, lsl #5	; +y*32 = y*160
	bl plot_horizontal_line

	mov r0, #Horizontal_Divider_3
	add r9, r12, r0, lsl #7	; y*128
	add r9, r9, r0, lsl #5	; +y*32 = y*160
	bl plot_horizontal_line

	ldr pc, [sp], #4


; R10 = value (0-64).
; R11 = y pos on screen.
; Preserve R0 please.
plot_vu_bar:
	str lr, [sp, #-4]!
	add r9, r12, r11, lsl #7	; y*128
	add r9, r9, r11, lsl #5		; +y*32 = y*160

	mov r1, r10, lsr #2		; div 4 (0-16)
	cmp r1, #16
	movge r1, #15			; clamp to 15.

	orr r1, r1, r1, lsl #4	; duplicate nibble.
	orr r1, r1, r1, lsl #8	; duplicate byte.
	orr r1, r1, r1, lsl #16	; duplicate word.

	mov r2, r1
	mov r3, r1
	mov r4, r1
	mov r5, r1
	mov r6, r1
	mov r7, r1
	mov r8, r1

	.rept VU_Bars_Height
	bl plot_horizontal_line
	.endr

	mov r1, #0
	mov r2, r1
	mov r3, r1
	mov r4, r1
	mov r5, r1
	mov r6, r1
	mov r7, r1
	mov r8, r1
	
	.rept VU_Bars_Gap-VU_Bars_Height
	bl plot_horizontal_line
	.endr

	ldr pc, [sp], #4

; R9 = ptr to start of line.
; Assume R1-R8 contain screen data.
plot_horizontal_line:
	stmia r9!, {r1-r8}		; 32 bytes
	stmia r9!, {r1-r8}		; 32 bytes
	stmia r9!, {r1-r8}		; 32 bytes
	stmia r9!, {r1-r8}		; 32 bytes
	stmia r9!, {r1-r8}		; 32 bytes
	mov pc, lr

; ============================================================================
; Additional code modules
; ============================================================================

screen_addr:
	.long 0					; ptr to the current VIDC screen bank being written to.

.include "src/scroller.asm"
.include "src/small-font-plot.asm"
.include "src/sprites.asm"
.include "src/logo-plot.asm"
.include "lib/mode9-palette.asm"
.include "lib/mode9-screen.asm"
.include "lib/lz4-decode.asm"

; ============================================================================
; Data Segment
; ============================================================================

vdu_disable_cursor:
.byte 23,1,0,0,0,0,0,0,0,0
.align 4

vdu_set_border_red:
.byte 19,0,24,255,0,0
.align 4

vdu_set_border_green:
.byte 19,0,24,0,255,0
.align 4

vdu_set_border_black:
.byte 19,0,24,0,0,0
.align 4

; TODO: Should be in BSS segment.
.align 4
palette_osword_block:
    .skip 8
    ; logical colour
    ; physical colour (16)
    ; red
    ; green
    ; blue
    ; (pad)

scroller_text_string:
	.include "src/scrolltxt-final.asm"
	.align 4
scroller_text_string_end:

.align 4
menu_table:
	.long menu_01_string - menu_table
	.long menu_02_string - menu_table
	.long menu_03_string - menu_table
	.long menu_04_string - menu_table
	.long menu_05_string - menu_table
	.long menu_06_string - menu_table
	.long menu_07_string - menu_table
	.long menu_08_string - menu_table
	.long menu_09_string - menu_table
	.long menu_10_string - menu_table
	.long menu_11_string - menu_table
	.long menu_12_string - menu_table

.equ MENU_SONG_XPOS, 3
.equ MENU_ARTIST_XPOS, 23
.equ MENU_TOP_YPOS, 114
.equ MENU_ROW_HEIGHT, 7

.align 4
menu_setup:
	.byte 17, 15	; define text colour 15
	.byte 0

.align 4
menu_playing:
	.byte 17, 6		; define text colour 6
	.byte 0

.align 4
menu_01_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS, "SWITCHING LANES", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS, "BY JUICE", 0

.align 4
menu_02_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+1*MENU_ROW_HEIGHT, "BRATGRUMBEERE", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+1*MENU_ROW_HEIGHT, "BY VIRGILL", 0

.align 4
menu_03_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+2*MENU_ROW_HEIGHT, "RED DROPS", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+2*MENU_ROW_HEIGHT, "BY OKEANOS", 0

.align 4
menu_04_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+3*MENU_ROW_HEIGHT, "AMIGA FUNERAL", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+3*MENU_ROW_HEIGHT, "BY VIRGILL", 0

.align 4
menu_05_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+4*MENU_ROW_HEIGHT, "A VIRAG ELSZARADT", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+4*MENU_ROW_HEIGHT, "BY DALEZY", 0

.align 4
menu_06_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+5*MENU_ROW_HEIGHT, "PAWS AND CLAWS", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+5*MENU_ROW_HEIGHT, "BY SLASH", 0

.align 4
menu_07_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+6*MENU_ROW_HEIGHT, "RESURGENCE", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+6*MENU_ROW_HEIGHT, "BY VEDDER", 0

.align 4
menu_08_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+7*MENU_ROW_HEIGHT, "QUICKSHOT DRAMAKING", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+7*MENU_ROW_HEIGHT, "BY CURT COOL", 0

.align 4
menu_09_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+8*MENU_ROW_HEIGHT, "SYNCOPATED GROOVE", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+8*MENU_ROW_HEIGHT, "BY OKEANOS", 0

.align 4
menu_10_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+9*MENU_ROW_HEIGHT, "PAULA AT THE DISCO", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+9*MENU_ROW_HEIGHT, "BY TRIACE", 0

.align 4
menu_11_string:
	.byte 31, MENU_SONG_XPOS, MENU_TOP_YPOS+10*MENU_ROW_HEIGHT, "CONCORDIA", 31, MENU_ARTIST_XPOS, MENU_TOP_YPOS+10*MENU_ROW_HEIGHT, "BY MA2E", 0

.align 4
menu_12_string:
	.byte 17, 8		; define text colour 8
	.byte 31, 32, MENU_TOP_YPOS+11*MENU_ROW_HEIGHT, "AUTOPLAY", 0

.align 4
logo_pal_block:
.incbin "build/logo.bin.pal"

.align 4
logo_data:
.incbin "build/logo.bin"

.align 4
music_table:
	.long music_01_mod - music_table
	.long music_02_mod - music_table
	.long music_03_mod - music_table
	.long music_04_mod - music_table
	.long music_05_mod - music_table
	.long music_06_mod - music_table
	.long music_07_mod - music_table
	.long music_08_mod - music_table
	.long music_09_mod - music_table
	.long music_10_mod - music_table
	.long music_11_mod - music_table

.align 4
scroller_font_data:
.incbin "build/scroller_font.bin"

.align 4
note_sprite_data:
.incbin "build/note1.bin"
.incbin "build/note2.bin"
.incbin "build/note3.bin"
.incbin "build/note4.bin"
.incbin "build/note5.bin"

.align 4
music_01_mod:
.incbin "build/music_01.bin"

.align 4
music_02_mod:
.incbin "build/music_02.bin"

.align 4
music_03_mod:
.incbin "build/music_03.bin"

.align 4
music_04_mod:
.incbin "build/music_04.bin"

.align 4
music_05_mod:
.incbin "build/music_05.bin"

.align 4
music_06_mod:
.incbin "build/music_06.bin"

.align 4
music_07_mod:
.incbin "build/music_07.bin"

.align 4
music_08_mod:
.incbin "build/music_08.bin"

.align 4
music_09_mod:
.incbin "build/music_09.bin"

.align 4
music_10_mod:
.incbin "build/music_10.bin"

.align 4
music_11_mod:
.incbin "build/music_11.bin"

; ============================================================================
; BSS Segment
; ============================================================================
