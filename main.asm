.define ROM_NAME "NOISE"

.zeropage
dpTmp0: .res 1, $00
dpTmp1: .res 1, $00
dpTmp2: .res 1, $00
dpTmp3: .res 1, $00
dpTmp4: .res 1, $00
dpTmp5: .res 1, $00

.code 
.include "snes/lorom128.inc"
.include "snes/snes_registers.asm"
.include "snes/startup.inc"
.include "snes/graphics.asm"
.include "audio.asm"
; .include "joycon2.asm"
; .include "alpha_map.asm"
; .include "kb_selector.asm"
; .include "delay.asm"
; .include "palette_snes.asm"
; .include "input.asm"
; .include "scenes/title.asm"
; .include "scenes/game.asm"

.code
; Follow set up in chapter 23 of manual
Reset:
    ; Not in manual but part of common cpu setup
    startup_init_cpu
    
    ; Move to force blank and clear all the registers
    startup_clear_registers

	; cleanup a bit of memory
    startup_clear_directpage

    lda #FORCE_BLANK | FULL_BRIGHT  
    sta INIDISP

    ; jsr reset_sprite_table

    ; Release VBlank
    lda #FULL_BRIGHT  ; Full brightness
    sta INIDISP

    ; Display Period begins now
    lda #(NMI_ON | AUTO_JOY_ON) ; enable NMI Enable and Joycon
    sta NMITIMEN

	; Do the infinite game loop
	jsr game_loop

	; Reset should never return
rts 


game_loop:
	wai ; Wait for NMI
	bra game_loop
	rts ; Should never actually return

game_vblank:
rts


VBlank:
    ; Push all the registers
    php ; processor status register
    pha
    phx
    phy

    ; Detect Beginning of VBlank (Appendix B-3)        
    lda RDNMI; Read NMI flag
    bpl endvblank ; loop if the MSB is 0 N=0  (positive number)

    ; TODO: set data changed registers and memory
    ; TODO: transfer renewed data via OAM
    ; TODO: change data settings for BG&OAM that renew picture

	; Do custom vblank
    jsr game_vblank

    endvblank: 
    ply
    plx
    pla
    plp
rti 

.segment "RODATA"
font_sloppy_transparent:
.incbin "assets/fonts/font_sloppy_transparent.pic"
font_sloppy_transparent_end:
