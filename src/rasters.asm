; ============================================================================
; Rasters via RasterMan.
; ============================================================================

rasters_init:
	; Init tables.
	adr r5, raster_tables
	ldmia r5, {r0-r3}
	add r0, r0, r5			; vidc table 1
	add r1, r1, r5			; vidc table 2
	add r2, r2, r5			; vidc table 3
	add r3, r3, r5			; memc table
	stmfd sp!, {r0-r3}

	mov r4, #0
	mov r6, #0x40000000		; set border colour black.
	mov r7, r6
	mov r8, r6
	mov r9, r6
	mov r5, #256
.1:
	stmia r0!, {r6-r9}		; 4x VIDC commands per line.
	stmia r1!, {r6-r9}		; 4x VIDC commands per line.
	stmia r2!, {r6-r9}		; 4x VIDC commands per line.
	stmia r2!, {r6-r9}		; 4x VIDC commands per line.
	str r4, [r3], #4
	str r4, [r3], #4
	subs r5, r5, #1

	bne .1
	ldmfd sp, {r0-r3}
	swi RasterMan_SetTables
	ldmfd sp!, {r0-r3}

    ; Add some actual rasters.
    ; Scroller area.
    ; Blue background gradient.
    mov r5, #247
	mov r6, #0x00000000		; set physical colour 0.
    str r6, [r0]            ; scanline 0.
.2:
    str r6, [r0, r5, lsl #4]
    add r6, r6, #0x200
    add r5, r5, #1
    cmp r5, #255
    bne .2

    ; Last line black!
	mov r6, #0x00000000		; set physical colour 0.
    str r6, [r0, r5, lsl #4]

    ; Scroller purple gradient.
    add r0, r0, #4          ; next VIDC command
    mov r5, #Scroller_Y_Pos+1
    ldr r6, raster_purple_gradient
.3:
    str r6, [r0, r5, lsl #4]
    sub r6, r6, #0x11
    tst r5, #1
    subne r6, r6, #0x100
    add r5, r5, #1
    cmp r5, #Scroller_Y_Pos + 17
    bne .3

    ldr r6, raster_purple_gradient
    str r6, [r0, r5, lsl #4]

    ; Menu area.
    mov r5, #Horizontal_Divider_1+2
    ldr r6, raster_menu_background
.4:
    str r6, [r0, r5, lsl #4]
    add r5, r5, #1
    cmp r5, #Horizontal_Divider_2-2
    bne .4

    ; Stave.
    mov r5, #VU_Bars_Y_Pos - VU_Bars_Gap
    ldr r6, raster_stave_colour
    mov r7, #0
    add r8, r0, r5, lsl #4
    mov r9, #5
.5:
	.rept VU_Bars_Height
    str r6, [r8], #16
    .endr
    .rept VU_Bars_Gap - VU_Bars_Height
    str r7, [r8], #16
    .endr
    subs r9, r9, #1
    bne .5

    mov pc, lr

; TODO: Would this just be easier with a pre-filled table?

raster_purple_gradient:
    .long 0x3c000fff        ; set physical colour 15 to white.

raster_menu_background:
    .long 0x18000733        ; menu background colour.

raster_stave_colour:
    .long 0x00000400        ; note stave background.

raster_tables:
	.long vidc_table_1 - raster_tables
	.long vidc_table_2 - raster_tables
	.long vidc_table_3 - raster_tables
	.long memc_table   - raster_tables
