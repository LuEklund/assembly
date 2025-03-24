.segment "HEADER"
    .byte "NES" ;Identificatiom string (required)
    .byte $1A
    .byte $01  ; PRG ROM size (1x 16KB)
    .byte $01  ; CHR ROM size (1x 8KB)
    .byte $00  ; Mapper 0, vertical mirroring
    .byte $00, $00, $00, $00
    .byte $00, $00, $00, $00
.segment "ZEROPAGE"
.segment "STARTUP"
.segment "VECTORS"
.segment "CHARS"



; Rest of your NES assembly code goes here...
