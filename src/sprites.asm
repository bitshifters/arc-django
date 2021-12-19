; Sprites.
; Simple MODE 9 masked sprites with pixel plotting.
; Assume colour 0 is transparent.

.equ Sprite_Width, 16
.equ Sprite_Height, 16
.equ Sprites_Num, 5

.equ Sprite_X_Pos, 0
.equ Sprite_Y_pos, 4
.equ Sprite_Data_Ptr, 8
.equ Sprite_Size, 16

; R0=X, R1=Y, R2=data ptr, R12=screen addr
plot_sprite:

    ; Calculate pixel offset.
    and r3, r0, #7          ; 8 pixels per word.
    bic r0, r0, #7          ; clamp X pos to word.

    ; Calculate screen plot address.
    add r9, r12, r1, lsl #7 ; 128 * y
    add r9, r9, r1, lsl #5  ; + 32 * y = 160 * y
    add r9, r9, r0, lsr #1  ; + x / 2

    ; Pixel offset shift.
    mov r10, r3, lsl #2     ; pixel shift (4*n)
    rsb r11, r10, #32       ; reverse pixel shift (32-4*n)

    ; For each line.
    mov r8, r2
    mov r7, #0 
    .1:

    ; ASSUME: Sprite_Width==16 (assert this?)
    ldmia r8!, {r0-r1}        ; read 16 pixels.
    ; Shift right by N pixels
    ; Screen: 01234567 Word: 76543210
    ; Copy right-most pixels into R2.
    mov r2, r1, lsr r11
    mov r1, r1, lsl r10
    orr r1, r1, r0, lsr r11
    mov r0, r0, lsl r10

    ldmia r9, {r4-r6}

    ; Compute mask.
    mov r3, #0
    tst r0, #0x0000000f
    orrne r3, r3, #0x0000000f
    tst r0, #0x000000f0
    orrne r3, r3, #0x000000f0
    tst r0, #0x00000f00
    orrne r3, r3, #0x00000f00
    tst r0, #0x0000f000
    orrne r3, r3, #0x0000f000
    tst r0, #0x000f0000
    orrne r3, r3, #0x000f0000
    tst r0, #0x00f00000
    orrne r3, r3, #0x00f00000
    tst r0, #0x0f000000
    orrne r3, r3, #0x0f000000
    tst r0, #0xf0000000
    orrne r3, r3, #0xf0000000

    ; Mask out screen bits, mask in sprite bits.    
    bic r4, r4, r3
    orr r4, r4, r0

    ; Compute mask.
    mov r3, #0
    tst r1, #0x0000000f
    orrne r3, r3, #0x0000000f
    tst r1, #0x000000f0
    orrne r3, r3, #0x000000f0
    tst r1, #0x00000f00
    orrne r3, r3, #0x00000f00
    tst r1, #0x0000f000
    orrne r3, r3, #0x0000f000
    tst r1, #0x000f0000
    orrne r3, r3, #0x000f0000
    tst r1, #0x00f00000
    orrne r3, r3, #0x00f00000
    tst r1, #0x0f000000
    orrne r3, r3, #0x0f000000
    tst r1, #0xf0000000
    orrne r3, r3, #0xf0000000

    ; Mask out screen bits, mask in sprite bits.    
    bic r5, r5, r3
    orr r5, r5, r1

    ; Compute mask.
    mov r3, #0
    tst r2, #0x0000000f
    orrne r3, r3, #0x0000000f
    tst r2, #0x000000f0
    orrne r3, r3, #0x000000f0
    tst r2, #0x00000f00
    orrne r3, r3, #0x00000f00
    tst r2, #0x0000f000
    orrne r3, r3, #0x0000f000
    tst r2, #0x000f0000
    orrne r3, r3, #0x000f0000
    tst r2, #0x00f00000
    orrne r3, r3, #0x00f00000
    tst r2, #0x0f000000
    orrne r3, r3, #0x0f000000
    tst r2, #0xf0000000
    orrne r3, r3, #0xf0000000

    ; Mask out screen bits, mask in sprite bits.    
    bic r6, r6, r3
    orr r6, r6, r2

    stmia r9, {r4-r6}
    add r9, r9, #Screen_Stride

    add r7, r7, #1
    cmp r7, #Sprite_Height
    blt .1

    mov pc, lr
