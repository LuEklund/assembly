CONTROLLER_LATCH = $4016
CONTROLLER1_DATA = $4016
CONTROLLER2_DATA = $4017

CONTROLLER_MSK_A = $01
CONTROLLER_MSK_B = $02
CONTROLLER_MSK_SELECT = $04
CONTROLLER_MSK_START = $08
CONTROLLER_MSK_UP = $10
CONTROLLER_MSK_DOWN = $20
CONTROLLER_MSK_LEFT = $40
CONTROLLER_MSK_RIGHT = $80


.segment "HEADER"
	.byte "NES"		;identification string
	.byte $1A
	.byte $02		;amount of PRG ROM in 16K units
	.byte $01		;amount of CHR ROM in 8K units
	.byte $00		;mapper and mirroing
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00
.segment "ZEROPAGE"
DIRECTIONS:     .RES 1 ; RLUD PREV and NEW Directions
HEAD_ON_BODY:    .RES 1  ; Will be used for collison check
SNEK_LEN:       .RES 1
TIMER:          .RES 1 ;SLow Snake down
PLAYER_SPRITE:	.RES 168	;APple head and bodies
controller_data: .RES 1
.segment "STARTUP"
RESET:
	SEI 		;disables interupts
	CLD			;turn off decimal mode
	

    LDX #$FF    ; init stack
    TXS

	LDX #%1000000	;disable sound IRQ
	STX $4017
	LDX #$00
	STX $4010		;disable PCM
	
	;initialize the stack register
	LDX #$FF
	TXS 		;transfer x to the stack
	
	; Clear PPU registers
	LDX #$00
	STX $2000
	STX $2001
	
	;WAIT FOR VBLANK
:
	BIT $2002
	BPL :-
	
	;CLEARING 2K MEMORY
	TXA
CLEARMEMORY: ;$0000 - $07FF
    STA $0000, X
    STA $0100, X
    STA $0300, X
    STA $0400, X
    STA $0500, X
    STA $0600, X
    STA $0700, X

        LDA #$FF
        STA $0200, X
        LDA #$00

    INX
    CPX #$00
    BNE CLEARMEMORY

    ;WAIT FOR VBLANK
:
    BIT $2002
    BPL :-

    ;Setting SPrites range
    LDA #$02
    STA $4014

    NOP

    LDA #$3F ;HOW DOES THIS WORK??? load MSB and then LSB?
    STA $2006
    LDA #$00
    STA $2006

    ;Setup Player Direction
    LDX #%00001000
    STX DIRECTIONS
    ;Snek Snek len + APEL!!!!!
    LDX #%00000101
    STX SNEK_LEN
    ;Timer Clear
    LDX #$00
    STX TIMER

    LDX #$00
LOADPALETTES:
    LDA PALETTEDATA, X
    STA $2007
    INX
    CPX #$20
    BNE LOADPALETTES


    ;Copy sprites from ROM to RAM

    LDX #$00
COPY_PLAYER_SPRITE:
    LDA SPRITEDATA, X
    STA PLAYER_SPRITE, X
    INX
    CPX #$08
    BNE COPY_PLAYER_SPRITE
COPY_PLAYER_BODY:
    LDY #$08
    LDA SPRITEDATA, Y ; Y POS
    STA PLAYER_SPRITE, X
    INX
    INY
    LDA SPRITEDATA, Y ; SPRITE
    STA PLAYER_SPRITE, X
    INX
    INY
    LDA SPRITEDATA, Y ; ATTRIBUTES
    STA PLAYER_SPRITE, X
    INX
    INY
    LDA SPRITEDATA, Y ; X POS
    STA PLAYER_SPRITE, X
    INX
    CPX #$A0
    BNE COPY_PLAYER_BODY

    JSR load_sprites




    
    ; RESET SCROLL
    LDA #$00
    STA $2005
    STA $2005
    ;ENABLE INTERUPS
    CLI

    LDA #%10010000
    STA $2000

    LDA #%00011110
    STA $2001

    ; Game loop RIGHT?
    INFLOOP:
        JSR controller_read_routine ;get controller pressed
        JSR update_direction_routine ;validate movement
        JSR move_player_routine
:
    	BIT $2002
	    BPL :-
        JMP INFLOOP



    ;Load sprites
load_sprites:
    LDX SNEK_LEN
    LDA #$00
    MULTI:
        CLC
        ADC #$04
        DEX
        BNE MULTI
    TAX
    DEX
LOADSPRITES_LOOP:
    LDA PLAYER_SPRITE, X
    STA $0200, X
    DEX
    CPX #$00
    BNE LOADSPRITES_LOOP
    LDA PLAYER_SPRITE, X
    STA $0200, X
    RTS


controller_read_routine:
  lda #$01
  sta CONTROLLER_LATCH
  lda #$00
  sta CONTROLLER_LATCH
  .repeat 8
    lda CONTROLLER1_DATA
    lsr
    ror controller_data
  .endrepeat
  rts

update_direction_routine:
        ;Move Down
        LDA controller_data
        AND #CONTROLLER_MSK_DOWN
        CLC
        ADC #$FF
        BCC NO_DOWN
        LDA DIRECTIONS
        EOR #%00000010 ;UP bit check RLUD
        BEQ INVALID_MOVEMENT
        LDA #%00000001
        STA DIRECTIONS
        rts
    NO_DOWN:
        ; MOVE UP
        LDA controller_data
        AND #CONTROLLER_MSK_UP
        CLC
        ADC #$FF
        BCC NO_UP
        LDA DIRECTIONS
        EOR #%00000001 ;DOWN bit check RLUD
        BEQ INVALID_MOVEMENT
        LDA #%00000010
        STA DIRECTIONS
        rts
    NO_UP:
        ; MOVE RIGHT
        LDA controller_data
        AND #CONTROLLER_MSK_RIGHT
        CLC
        ADC #$FF
        BCC NO_RIGHT
        LDA DIRECTIONS
        EOR #%00000100 ;LEFT bit check RLUD
        BEQ INVALID_MOVEMENT
        LDA #%00001000
        STA DIRECTIONS
        rts
    NO_RIGHT:
        ; MOVE LEFT
        LDA controller_data
        AND #CONTROLLER_MSK_LEFT
        CLC
        ADC #$FF
        BCC NO_LEFT
        LDA DIRECTIONS
        EOR #%00001000 ;RIGHT bit check RLUD
        BEQ INVALID_MOVEMENT
        LDA #%00000100
        STA DIRECTIONS
        rts
    NO_LEFT:
    INVALID_MOVEMENT:
    rts

move_player_routine:
    ;TIMER check
    LDA TIMER
    CLC
    ADC SNEK_LEN
    CMP #$14
    STA TIMER
    BPL TIME_DONE
    rts
    TIME_DONE:


    ;GET HEAD POSITIONS
    LDY #$07
    LDX PLAYER_SPRITE, Y    ; Player X pos
    TXA
    LDX #$04
    LDY PLAYER_SPRITE, X       ; Player Y pos
    TAX
    PHA

    
    ; X-AXI
    LDX #$05
    LDA SPRITEDATA, X
    LDX #$05
    STA PLAYER_SPRITE, X

    PLA
    TAX

    ; RIght UPDATE
    LDA DIRECTIONS
    EOR #%00001000 ;Right
    BNE NOT_RIGHT
    TXA
    ADC #$07
    PHA ;save X value

    LDA #$00 ; Change direction of snake head
    LDX #$06
    STA PLAYER_SPRITE, X

    PLA ; retrieve X value
    TAX
    JMP MOVE_DONE
    NOT_RIGHT:
    ;Left UPDATE
    LDA DIRECTIONS
    EOR #%00000100 ;LEFT
    BNE NOT_LEFT
    TXA
    SBC #$08
    PHA

    LDA #%01000000 ; Change direction of snake head
    LDX #$06
    STA PLAYER_SPRITE, X

    PLA
    TAX
    JMP MOVE_DONE
    NOT_LEFT:


    ; Y-AXI
    TXA
    PHA

    LDX #$0D
    LDA SPRITEDATA, X
    LDX #$05
    STA PLAYER_SPRITE, X

    PLA
    TAX

    ;Up UPDATE
    LDA DIRECTIONS
    EOR #%00000010 ;Up
    BNE NOT_UP
    TYA
    SBC #$08
    PHA
    TXA
    PHA

    LDA #%10000000 ; Change direction of snake head
    LDX #$06
    STA PLAYER_SPRITE, X
    
    PLA
    TAX
    PLA
    TAY
    JMP MOVE_DONE
    NOT_UP:
    ;Down UPDATE
    LDA DIRECTIONS
    EOR #%00000001 ;DOWN
    BNE MOVE_DONE
    TYA
    ADC #$07
    PHA
    TXA
    PHA


    LDA #%00000000 ; Change direction of snake head
    LDX #$06
    STA PLAYER_SPRITE, X
    
    PLA
    TAX
    PLA
    TAY
    MOVE_DONE:
    

    TXA
    PHA
    TYA
    PHA


    ;On apple Y position?
    CMP PLAYER_SPRITE
    BNE NOT_APPLE
    TXA
    LDX #$03
    ; On apple X position
    CMP PLAYER_SPRITE, X
    BNE NOT_APPLE


    LDA #$00
    LDX TIMER
    MULTI_APPLE:
        CLC
        ADC #$08
        DEX
        CPX #$00
        BNE MULTI_APPLE
    STA TIMER
    LDX #$03 
    LDA PLAYER_SPRITE, X ; LOAD APPLE X POS
    CLC
    ADC TIMER
    LDX #$03
    STA PLAYER_SPRITE, X

    LDA PLAYER_SPRITE ; LOAD Y POS
    CLC
    ADC TIMER
    CLC
    CMP #$DF
    BCC VALID_Y_VALUE
    LDA #$DF
    VALID_Y_VALUE:

    STA PLAYER_SPRITE

    LDX SNEK_LEN ;Increase snek len
    INX
    STX SNEK_LEN

    CPX #$14
    BNE CONTINUE_GAME
        JMP RESET
    CONTINUE_GAME:

    NOT_APPLE:


    LDA SNEK_LEN
    DO_NEXT_BODY:
    JSR update_bodies_routine
    CLC
    SBC 1
    CMP #$02
    BNE DO_NEXT_BODY



    PLA
    LDX #$04
    STA PLAYER_SPRITE, X   ;Save new player Y pos
    PLA
    LDY #$07
    STA PLAYER_SPRITE, Y ; Save new player X pos


    ;RESET TIMER
    LDX #$00
    STX TIMER

    rts


update_bodies_routine:
    ;VALIDATE BODY MOVEMENT

    
    PHA ;save current len
    ; Y DIRECTIONs
    SEC
    SBC #$02
    ASL A
    ASL A

    TAX
    LDY PLAYER_SPRITE, X    ; BEFORE BODY Y POS
    
    CLC
    ADC #$04
    
    TAX ;save old Y Pos in HEAD_ON_BODY
    TYA
    LDY PLAYER_SPRITE, X
    STY HEAD_ON_BODY
    TAY
    STY PLAYER_SPRITE, X    ; CURRENT BODY Y POS
    TXA

    ;Y Collision check with HEAD
    LDX #$04
    LDY PLAYER_SPRITE, X
    CPY HEAD_ON_BODY
    BEQ NO_Y_COL
        LDX #$00
        STX HEAD_ON_BODY
    NO_Y_COL:

    ; X DIRECTIONs
    SEC 
    SBC #$01
    TAX
    LDY PLAYER_SPRITE, X    ; BEFORE BODY X POS

    CLC
    ADC #04

    PHA ;save important variables in stack
    TAX
    TYA
    PHA
    TXA

    LDX HEAD_ON_BODY
    CPX #$00
    BEQ NO_COL ;If Y collison then check X Collision  with head
    TAX     
    LDY PLAYER_SPRITE, X
    STY HEAD_ON_BODY
    LDX #$07
    LDY PLAYER_SPRITE, X
    CPY HEAD_ON_BODY
    BNE NO_COL
        JMP RESET
    NO_COL:
    LDX #$00
    STX HEAD_ON_BODY

    PLA ; retrieve important variables
    TAY
    PLA

    TAX
    STY PLAYER_SPRITE, X    ; CURRENT BODY X POS





    PLA ;Take next snake len before rts
    rts





NMI:
    JSR load_sprites
    LDA #$02
    STA $4014
    RTI

PALETTEDATA:
    ;.incbin "rom.pal"
	.byte $00, $0F, $00, $10, 	$00, $0A, $15, $01, 	$00, $29, $28, $27, 	$00, $34, $24, $14 	;background palettes
 .byte $01, $28, $1F, $21,     $01, $06, $15, $36,     $00, $0F, $30, $27,     $00, $3C, $2C, $1C 

	;.byte $31, $0F, $15, $30, 	$00, $0F, $11, $30, 	$00, $0F, $30, $27, 	$00, $3C, $2C, $1C 	;sprite palettes

SPRITEDATA:
    ;Y, SPRITE NUM, attributes, X
    .byte $37, $02, $01, $50 ; apel
   	.byte $37, $03, %00000000, $40 ;Snake head X-axi
    .byte $37, $01, $00, $38 ;Snake body
    .byte $00, $00, $00, $00 ;snake head Y-axi





.segment "VECTORS"
	.word NMI
	.word RESET
	; specialized hardware interurpts
.segment "CHARS"
	.incbin "rom.chr"
