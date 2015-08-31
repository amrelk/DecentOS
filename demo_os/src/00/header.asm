; This is the very start of the OS, and will end up at address 0x0000. It
; includes the code for each RST (restart), which I leave you to populate
; as you think of things to put here. It also includes some information
; the boot code will tweak that you need to successfully send an OS to your
; calculator.

; 0x0000
; RST 0x00
    jp boot
.fill 0x08-$
; 0x0008
; RST 0x08
    ret
.fill 0x10-$
; 0x0010
; RST 0x10
    ret
.fill 0x18-$
; 0x0018
; RST 0x18
    ret
.fill 0x20-$
; 0x0020
; RST 0x20
    ret
.fill 0x28-$
; 0x0028
; RST 0x28
    ret
.fill 0x30-$    
; 0x0030
; RST 0x30
    ret
.fill 0x38-$
; 0x0038
; RST 0x38
; SYSTEM INTERRUPT
    ;jp sysInterrupt
    ret
; 0x003B

.fill 0x53-$
; 0x0053
    jp boot
; 0x0056
.db 0xFF, 0xA5, 0xFF
#ifdef TI84pSE
.fill 0x64-$
    .db '2' ; For the sake of WabbitEmu
#endif
