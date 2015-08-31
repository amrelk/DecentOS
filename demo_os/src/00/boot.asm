; Most of this code is boot-up code that initializes everything into an
; enviornment you'll be comfortable-ish with.

boot:
    di ; Disable interrupts, since you don't have an interrupt handler ;)

    ld a, 6
    out (4), a ; Set memory mode 0

#ifdef FLASH4MB ; Configure high bits for TI-84+ CSE Flash paging
    xor a
    out (0x0E), a
    out (0x0F), a
#endif

; Map memory to something resembling TIOS (and what KnightOS uses, as a matter of fact)
; We have to do this differently depending on which calculator we're on. We set the
; memory mapping as follows:
; Bank 0: Flash Page 00
; Bank 1: Flash Page *
; Bank 2: RAM Page 01
; Bank 3: RAM Page 00 ; In this order for consistency with TI-83+ and TI-73 mapping
    ld a, 6
    out (4), a
#ifdef CPU15
    ld a, 0x81
    out (7), a
#else
    ld a, 0x41
    out (7), a
#endif

    ; We can start using the end of RAM as a stack at this point
    ; Note that until you set SP and make sure there's RAM around for your stack
    ; to live in, you cannot use PUSH/POP, CALL, RST, etc.
    ld sp, 0

#ifdef COLOR
    ; Set GPIO config for the CSE
    ld a, 0xE0
    out (0x39), a
    ; Set up the color LCD
    call colorLcdOn
    call clearColorLcd
#else
    ; Initialize B&W LCD
    ld a, 0x05
    call lcdDelay
    out (0x10), a ; X-Increment Mode
    ld a, 0x01
    call lcdDelay
    out (0x10), a ; 8-bit mode
    ld a, 3
    call lcdDelay
    out (0x10), a ; Enable screen
    ld a, 0x17
    call lcdDelay
    out (0x10), a ; Op-amp control (OPA1) set to max (with DB1 set for some reason)
    ld a, 0xB ; B
    call lcdDelay
    out (0x10), a ; Op-amp control (OPA2) set to max
    #ifdef USB
        ld a, 0xEF
    #else
        #ifdef TI73
            ld a, 0xFB
        #else
            ld a, 0xF4
        #endif
    #endif
    call lcdDelay
    out (0x10), a ; Set contrast, with some sensible defaults based on the model in use
#endif

    ; Boot up complete, do whatever you want here
    ; The screen has been initialized, memory mapped nicely, and a stack
    ; is ready for you at the end of RAM. For this demo, we're going to
    ; draw a simple smiley face on the LCD.
    
#ifndef COLOR ; Doing this for color calculators is an excecise left up to the reader
    
    ld iy, 0x8000 ; We'll use 0x8000 as our screen buffer
    call clearBuffer
    ld hl, sprite
    ld de, 0x2C1D ; X, Y
    ld b, 5
    call putSpriteOR
    call fastCopy
    jr $

sprite:
    .db 0b01010000
    .db 0b01010000
    .db 0b00000000
    .db 0b10001000
    .db 0b01110000

#endif
