; ============================================================================
; Menu stuff.
; ============================================================================

.equ MENU_SONG_XPOS, 3
.equ MENU_ARTIST_XPOS, 23
.equ MENU_TOP_YPOS, 114
.equ MENU_ROW_HEIGHT, 7

current_key:
	.long 0

held_key:
	.long 0

prev_mouse_y:
	.long 0

mouse_delta_y:
	.long 0

selection_colour:
	.long 0

update_menu:
	str lr, [sp, #-4]!

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

	ldr pc, [sp], #4

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
