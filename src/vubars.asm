; ============================================================================
; VU bars
; ============================================================================

.equ Raster_VU_Bars, 1

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

.if Raster_VU_Bars == 0
	; Some fake bars to blank the sprites.
	mov r10, #0
	mov r11, #VU_Bars_Y_Pos - 2 * VU_Bars_Gap
	bl plot_vu_bar

	mov r10, #0
	mov r11, #VU_Bars_Y_Pos - 1 * VU_Bars_Gap
	bl plot_vu_bar
.else
    ; Blank sprite area.
    mov r1, #0
    bl copy_1_to_8
    mov r0, #Horizontal_Divider_2 + 1
	add r9, r12, r0, lsl #7	; y*128
	add r9, r9, r0, lsl #5	; +y*32 = y*160
    mov r10, #Horizontal_Divider_3 - Horizontal_Divider_2 - 2
    .1:
    bl plot_horizontal_line
    subs r10, r10, #1
    bne .1
.endif

	ldr pc, [sp], #4

plot_dividers:
	str lr, [sp, #-4]!

    ldr r1, divider_colour_word
    bl copy_1_to_8

	ldr r12, screen_addr

	mov r0, #Horizontal_Divider_1
	bl plot_horizontal_line_R0

    ldr r1, small_font_bg_word
    bl copy_1_to_8

    add r9, r9, #Screen_Stride
    mov r10, #Horizontal_Divider_2 - Horizontal_Divider_1 - 3
    .1:
    bl plot_horizontal_line
    subs r10, r10, #1
    bne .1

    ldr r1, divider_colour_word
    bl copy_1_to_8

	mov r0, #Horizontal_Divider_2
	bl plot_horizontal_line_R0

	mov r0, #Horizontal_Divider_3
	bl plot_horizontal_line_R0

	ldr pc, [sp], #4

divider_colour_word:
    .long 0xcccccccc

; R10 = value (0-64).
; R11 = y pos on screen.
; Preserve R0 please.
plot_vu_bar:
	str lr, [sp, #-4]!

.if Raster_VU_Bars == 0
	add r9, r12, r11, lsl #7	; y*128
	add r9, r9, r11, lsl #5		; +y*32 = y*160

	mov r1, r10, lsr #2		; div 4 (0-16)
	cmp r1, #16
	movge r1, #15			; clamp to 15.

	orr r1, r1, r1, lsl #4	; duplicate nibble.
	orr r1, r1, r1, lsl #8	; duplicate byte.
	orr r1, r1, r1, lsl #16	; duplicate word.

    bl copy_1_to_8

	.rept VU_Bars_Height
	bl plot_horizontal_line
	.endr

	mov r1, #0
	bl copy_1_to_8

	.rept VU_Bars_Gap-VU_Bars_Height
	bl plot_horizontal_line
	.endr
.else
    ; Raster version.
    adr r9, raster_tables
    ldr r8, [r9]
    add r8, r8, r9              ; VIDC table 1.

	mov r1, r10, lsr #2		    ; div 4 (0-16)
	cmp r1, #16
	movge r1, #15			    ; clamp to 15.
    mov r1, r1, lsl #8          ; blue

    add r8, r8, r11, lsl #4     ; raster line.
    add r8, r8, #4              ; VIDC command 2
    str r1, [r8, #-16]          ; on previous line.
.endif
	ldr pc, [sp], #4

copy_1_to_8:
	mov r2, r1
	mov r3, r1
	mov r4, r1
	mov r5, r1
	mov r6, r1
	mov r7, r1
	mov r8, r1
    mov pc, lr

; R0 = line no.
; R12 = screen address.
plot_horizontal_line_R0:
	add r9, r12, r0, lsl #7	; y*128
	add r9, r9, r0, lsl #5	; +y*32 = y*160
; FALL THROUGH!

; R9 = ptr to start of line.
; Assume R1-R8 contain screen data.
plot_horizontal_line:
	stmia r9!, {r1-r8}		; 32 bytes
	stmia r9!, {r1-r8}		; 32 bytes
	stmia r9!, {r1-r8}		; 32 bytes
	stmia r9!, {r1-r8}		; 32 bytes
	stmia r9!, {r1-r8}		; 32 bytes
	mov pc, lr
