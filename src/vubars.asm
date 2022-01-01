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
