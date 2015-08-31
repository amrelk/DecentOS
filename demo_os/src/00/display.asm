; Some simple display functions from the KnightOS kernel

#ifndef COLOR ; B&W screens
.define clip_mask 0xC000 ; You probably want to change this

lcdDelay:
    push af
_:    in a,(0x10)
    rla
    jr c,-_
    pop af
    ret

;; clearBuffer [Display]
;;  Turns off all pixels on a screen buffer.
;; Inputs:
;;  IY: Screen buffer
clearBuffer:
    push hl
    push de
    push bc
        push iy \ pop hl
        ld (hl), 0
        ld d, h
        ld e, l
        inc de
        ld bc, 767
        ldir
    pop bc
    pop de
    pop hl
    ret

;; fastCopy [Display]
;;  Copies the screen buffer to the LCD (this is Ion's function)
;; Inputs:
;;  IY: Screen buffer
fastCopy:
        push hl
        push bc
        push af
        push de
            ld a, i
            push af
                di
                push iy \ pop hl
    
                ld c, 0x10
                ld a, 0x80
.setRow:
                in f, (c)
                jp m, .setRow
                out (0x10), a
                ld de, 12
                ld a, 0x20
.col:
                in f, (c)
                jp m, .col
                out (0x10),a
                push af
                    ld b,64
.row:
                    ld a, (hl)
.rowWait:
                    in f, (c)
                    jp m, .rowWait
                    out (0x11), a
                    add hl, de
                    djnz .row
                pop af
                dec h
                dec h
                dec h
                inc hl
                inc a
                cp 0x2C
                jp nz, .col
            pop af
        jp po, _
        ei
_:  pop de
    pop af
    pop bc
    pop hl
    ret

;; putSpriteOR [Display]
;;  Draws an 8xB sprite on the screen buffer using OR (turns pixels ON) logic.
;; Inputs:
;;  IY: Screen buffer
;;  HL: Sprite pointer
;;  D, E: X, Y
;;  B: Height
putSpriteOR:
    push af
    push bc
    push hl
    push de
    push ix
        push hl \ pop ix
        call .clipSprOR
    pop ix
    pop de
    pop hl
    pop bc
    pop af
    ret
    
.clipSprOR:
        ; Start by doing vertical clipping
        ld a, 0b11111111         ; Reset clipping mask
        ld (clip_mask), a
        ld a, e                  ; If ypos is negative
        or a                     ; try clipping the top
        jp m, .clipTop3

        sub 64                   ; If ypos is >= 64
        ret nc                   ; sprite is off-screen

        neg                      ; If (64 - ypos) > height
        cp b                     ; don't need to clip
        jr nc, .vertClipDone3

        ld b, a                  ; Do bottom clipping by
        jr .vertClipDone3        ; setting height to (64 - ypos)

.clipTop3:
        ld a, b                  ; If ypos <= -height
        neg                      ; sprite is off-screen
        sub e
        ret nc

        push af
            add a, b             ; Get the number of clipped rows
            ld e, 0              ; Set ypos to 0 (top of screen)
            ld b, e              ; Advance image data pointer
            ld c, a
            add ix, bc
        pop af
        neg                      ; Get the number of visible rows
        ld b, a                  ; and set as height

.vertClipDone3:
        ; Now we're doing horizontal clipping
        ld c, 0                  ; Reset correction factor
        ld a, d

        cp -7                    ; If 0 > xpos >= -7
        jr nc, .clipLeft3        ; clip the left side

        cp 96                    ; If xpos >= 96
        ret nc                   ; sprite is off-screen

        cp 89                    ; If 0 <= xpos < 89
        jr c, .horizClipDone3    ; don't need to clip

.clipRight3:
        and 7                    ; Determine the clipping mask
        ld c, a
        ld a, 0b11111111
.findRightMask3:
        add a, a
        dec c
        jr nz, .findRightMask3
        ld (clip_mask), a
        ld a, d
        jr .horizClipDone3

.clipLeft3:
        and 7                    ; Determine the clipping mask
        ld c, a
        ld a, 0b11111111
.findLeftMask3:
        add a, a
        dec c
        jr nz, .findLeftMask3
        cpl
        ld (clip_mask), a
        ld a, d
        add a, 96                ; Set xpos so sprite will "spill over"
        ld c, 12                 ; Set correction

.horizClipDone3:
        ; A = xpos
        ; E = ypos
        ; B = height
        ; IX = image address

        ; Now we can finally display the sprite.
        ld h, 0
        ld d, h
        ld l, e
        add hl, hl
        add hl, de
        add hl, hl
        add hl, hl

        ld e, a
        srl e
        srl e
        srl e
        add hl, de

        push iy \ pop de
        add hl, de

        ld d, 0                 ; Correct graph buffer address
        ld e, c                 ; if clipping the left side
        sbc hl, de

        and 7
        jr z, .aligned3

        ld c, a
        ld de, 11

.rowLoop3:
        push bc
            ld b, c
            ld a, (clip_mask)        ; Mask out the part of the sprite
            and (ix)                 ; to be horizontally clipped
            ld c, 0

.shiftLoop3:
            srl a
            rr c
            djnz .shiftLoop3

            or (hl)
            ld (hl), a

            inc hl
            ld a, c
            or (hl)
            ld (hl), a

            add hl, de
            inc ix
        pop bc
        djnz .rowLoop3
        ret

.aligned3:
        ld de, 12

.putLoop3:
        ld a, (ix)
        or (hl)
        ld (hl), a
        inc ix
        add hl, de
        djnz .putLoop3
        ret

#else ; Color screens

;; writeLcdRegister [Color]
;;  Writes a 16-bit value to a color LCD register
;; Inputs:
;;  A: Register
;;  HL: Value
;; Comments:
;;  Destroys C
writeLcdRegister:
    out (0x10), a \ out (0x10), a
    ld c, 0x11
    out (c), h
    out (c), l
    ret

;; readLcdRegister [Color]
;;  Reads a 16-bit value from a color LCD register
;; Inputs:
;;  A: Register
;; Outputs:
;;  HL: Value
;; Comments:
;;  Destroys C
readLcdRegister:
    out (0x10), a \ out (0x10), a
    ld c, 0x11
    in h, (c)
    in l, (c)
    ret

colorLcdWait:
    ld b, 0xAF
    ld c, 0xFF
    ld hl, 0x8000
.loop:
    ld a, (hl)
    ld (hl), a
    dec bc
    ld a, c
    or b
    jp nz, .loop
    ret

;; colorLcdOn [Color]
;;  Initializes and turns on the color LCD.
colorLcdOn:
    ; Note: Optimize this, it could be a lot faster
    ld a, 0x0D
    out (0x2A), a ; LCD delay
    lcdout(0x07, 0x0000) ; Reset Disp.Ctrl.1: LCD scanning, command processing OFF
    lcdout(0x06, 0x0000)
    ;lcdout(0x10, 0x07F1) ; Reset Pwr.Ctrl.1: Start RC oscillator, set voltages
    lcdout(0x11, 0x0007) ; Pwr.Ctrl.2: Configure voltages
    lcdout(0x12, 0x008C) ; Pwr.Ctrl.3: More voltages
    lcdout(0x13, 0x1800) ; Pwr.Ctrl.4: Take a wild guess
    lcdout(0x29, 0x0030) ; Pwr.Ctrl.7: I'm not an LCD engineer, don't ask me.
    call colorLcdWait
    lcdout(0x10, 0x0190) ; Init Pwr.Ctrl.1: Exit standby, fiddle with voltages, enable
    lcdout(0x11, 0x0227) ; Pwr.Ctrl.2: Configure voltages
    lcdout(0x06, 0x0001)
    call colorLcdWait
    call colorLcdWait
    lcdout(0x01, 0x0000) ; Reset Out.Ctrl.1: Ensure scan directions are not reversed
    lcdout(0x02, 0x0200) ; LCD Driving Control: Sets inversion mode=line inversion and disables it
    lcdout(0x03, 0x10b8) ; Init. Entry Mode: Cursor moves up/down, down, left, disable
    lcdout(0x08, 0x0202) ; Set front & back porches: 2 blank lines top & bottom
    lcdout(0x09, 0x0000) ; Reset Disp.Ctrl.3: Resets scanning stuff and off-screen voltage
    lcdout(0x0A, 0x0000) ; Disp.Ctrl.4: No FMARK
    lcdout(0x0C, 0x0000) ; RGB Disp.: Off
    lcdout(0x0D, 0x0000) ; FMARK position: Off
    lcdout(0x60, 0x2700) ; Driver Output Ctrl. 2
    lcdout(0x61, 0x0001) ; Base Image Display Ctrl: Use color inversion, no vertical scroll, reset voltage in non-display level
    lcdout(0x6A, 0x0000) ; Reset Vertical Scroll Ctrl.
    lcdout(0x90, 0x0010)
    lcdout(0x92, 0x0600)
    lcdout(0x95, 0x0200)
    lcdout(0x97, 0x0c00)
    lcdout(0x30, 0x0000) ; Gamma Control 1
    lcdout(0x31, 0x0305) ; Gamma Control 2
    lcdout(0x32, 0x0002) ; Gamma Control 3
    lcdout(0x35, 0x0301) ; Gamma Control 4
    lcdout(0x36, 0x0004) ; Gamma Control 5
    lcdout(0x37, 0x0507) ; Gamma Control 6
    lcdout(0x38, 0x0204) ; Gamma Control 7
    lcdout(0x39, 0x0707) ; Gamma Control 8
    lcdout(0x3C, 0x0103) ; Gamma Control 9
    lcdout(0x3D, 0x0004) ; Gamma Control 10
    lcdout(0x50, 0x0000) ; Horiz.Win.Start: 0
    lcdout(0x51, 0x00EF) ; Horiz.Win.End: 239 = 240-1
    lcdout(0x52, 0x0000) ; Vert.Win.Start: 0
    lcdout(0x53, 0x013F) ; Vert.Win.End: 319 = 320-1
    lcdout(0x2B, 0x000B) ; Set frame rate to 70
    lcdout(0x10, 0x1190) ; Init Pwr.Ctrl.1: Exit standby, fiddle with voltages, enable
    lcdout(0x07, 0x0001) ; Reset Disp.Ctrl.1: LCD scanning, command processing OFF
    call colorLcdWait
    call colorLcdWait
    lcdout(0x07, 0x0023) ; Reset Disp.Ctrl.1: LCD scanning, command processing OFF
    call colorLcdWait
    call colorLcdWait
    lcdout(0x07, 0x0133) ; Disp.Ctrl.1: LCD scan & light on, ready to enter standby
    ; Turn on backlight
    in a, (0x3A)
    set 5, a
    out (0x3A), a
    xor a
    lcdout(0x03, 0x10B8) ; Entry mode the way we want it
    ret

;; colorLcdOff [Color]
;;  Turns off the color LCD and backlight.
colorLcdOff:
    lcdout(0x07, 0x00)
    call colorLcdWait
    lcdout(0x10, 0x07F0)
    call colorLcdWait
    lcdout(0x10, 0x07F1)
    ; Turn off backlight
    in a, (0x3A)
    res 5, a
    out (0x3A), a
    ret

;; clearColorLcd [Color]
;;  Sets all pixels on the LCD to grey.
clearColorLcd:
    push af
    push hl
    push bc
        ; Set window
        ld a, 0x50
        ld hl, 0
        call writeLcdRegister
        inc a \ ld hl, 239
        call writeLcdRegister
        inc a \ ld hl, 0
        call writeLcdRegister
        inc a \ ld hl, 319
        call writeLcdRegister
        ; Set cursor
        ld a, 0x20
        ld hl, 0
        call writeLcdRegister
        inc a
        call writeLcdRegister
        inc a
        ; Select GRAM
        out (0x10), a \ out (0x10), a
        ld c, 240
.outerLoop:
        ld b, 160
.innerLoop:
        ; Two pixels per iteration
        ld a, 0b10100101
        out (0x11), a
        ld a, 0b00110100
        out (0x11), a
        ld a, 0b10100101
        out (0x11), a
        ld a, 0b00110100
        out (0x11), a
        djnz .innerLoop
        dec c
        jr nz, .outerLoop
    pop bc
    pop hl
    pop af
    ret
#endif
