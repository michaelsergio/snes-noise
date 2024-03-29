.define ROM_NAME "Noise Demo"

.include "snes_registers.asm"
.include "lorom128.inc"
.include "startup.inc"
.include "graphics.asm"
; .include "joycon.asm"
.include "level_basic_tile.asm"
.include "screen_scroll.asm"
.include "input.asm"
.include "audio.asm"

; Include the SPC audio program load position and size
.import __SPCIMAGE_LOAD__, __SPCIMAGE_SIZE__


.zeropage
dpTmp0: .res 1, $00
dpTmp1: .res 1, $00
dpTmp2: .res 1, $00
dpTmp3: .res 1, $00
dpTmp4: .res 1, $00
dpTmp5: .res 1, $00
wJoyInput: .res 2, $0000

bSpritePosX: .res 1, $00
bSpritePosY: .res 1, $00

.code
; Follow set up in chapter 23 of manual
Reset:
    ; Not in manual but part of common cpu setup
    startup_init_cpu
    
    ; Move to force blank and clear all the registers
    startup_clear_registers

    ; Initialize zeropage
    startup_clear_directpage

	main_setup_video:
    jsr setup_video

    ; Release VBlank
    lda #FULL_BRIGHT  ; Full brightness
    sta INIDISP

    ; Display Period begins now
    lda #(NMI_ON | AUTO_JOY_ON) ; enable NMI Enable and Joycon
    sta NMITIMEN

	main_init: 

    stz bSpritePosX
    stz bSpritePosY
    lda #$5
    sta dpTmp5

    stz wJoyInput
    stz wJoyInput + 1

	; Transfer the audio program
    audio_init ^__SPCIMAGE_LOAD__, .loword(__SPCIMAGE_LOAD__), __SPCIMAGE_SIZE__
    
    game_loop:
        ; TODO: Gen data of register to be renewed & mem to change BG & OBJ data
        ; aka Update
        ; react to input
		; joycon_read_joy1_blocking wJoyInput
		; jsr check_inputs

        wai ; Wait for NMI
jmp game_loop


VBlank:
    ; Detect Beginning of VBlank (Appendix B-3)        
    lda RDNMI; Read NMI flag
    bpl endvblank ; loop if the MSB is 0 N=0  (positive number)

    ; TODO: set data changed registers and memory
    ; TODO: transfer renewed data via OAM
    ; TODO: change data settings for BG&OAM that renew picture

    ; Constant Screen Scrolling
    ; jsr screen_scroll_left

    ; Update the screen scroll register
	; screen_scroll_vupdate

    endvblank: 
rti 


PAL_FONT_A_ADDR = $00
PAL_BASIC_SET_ADDR = $10

setup_video:
    ; Main register settings
    ; Mode 0 is OK for now

    ; Set OAM, CGRAM Settings
    ; We're going to DMA the graphics instead of using 2121/2122
    ; These are Mode 0 palettes
    ; BG1 Starts at $00
    ;graphics_load_palette test_font_a_palette, PAL_BASIC_SET_ADDR, 4
    graphics_vload_palette palette_basic_set, PAL_BASIC_SET_ADDR, 4

    ; Color palettes for BG2 start at $20. 
    graphics_vload_palette palette_basic_set, $20, 4

    ;Sample palette
    jsr graphics_vload_sample_palette

    ; force Black BG by setting first color in first palette to black
    force_black_bg:
        stz CGADD
        stz CGDATA
        stz CGDATA

    ; Make sure hscroll is 0
    stz mBG1HOFS

    ; Set VRAM Settings
    ; Transfer VRAM Data via DMA

    ; Load tile data to VRAM
    ;jsr reset_tiles
    ;graphics_vload_block test_font_a_obj, $0000, $0020 ; 2 tiles, 2bpp * 8x8 / 8bits = 32 bytes
    graphics_vload_block font_charset, $0100, 640 ; 40 tiles, 2bpp * 8x8 / 8 bits= 
    graphics_vload_block tiles_basic_set, $0280, 128 ; 8 tiles, 2bpp * 8x8 / 8 bits = 128

    ; BG2 blocks
    BG2_VRAM_TILE_START = $2000
    graphics_vload_block tiles_basic_set, BG2_VRAM_TILE_START, (8*2*8) ; num * bpp * size

    jsr level_basic_tile_load_tilemap

    ; TODO: Transfer OAM, CGRAM Data via DMA (2 channels)
    jsr graphics_reset_sprite_table

    ; Register initial screen settings
    jsr register_screen_settings
rts

.macro load_size num_tile, bpp, tile_width 
    (num_tile * bpp * tile_width * tile_width / 8)
.endmacro

register_screen_settings:
    stz BGMODE  ; mode 0 8x8 4-color 4-bgs

    lda #$04    ; Tile Map Location - set BG1 tile offset to $0400 (Word addr) (0800 in vram) with sc_size=00
    sta BG1SC   ; BG1SC 

    lda #$18    ; Tile Map Location - set BG3 tile offset to $1800 (Word addr) (3000 in vram) with sc_size=00
    sta BG2SC   ; BG1SC 

    lda #$20
    sta BG12NBA ; BG1 name base address to $0000 (word addr) (Tiles offset)
    lda #$00
    sta BG34NBA ; BG3 name base address to $0000 (word addr) (Tiles offset)

    lda #(BG1_ON | BG2_ON | SPR_ON) ; Enable BG1 and Sprites as main screen.
    ;lda #BG1_ON ; Enable BG1 on The Main screen
    ;lda #SPR_ON ; Enable Sprites on The Main screen.
    sta TM

    lda #$FF    ; Scroll down 1 pixel (FF really 03FF 63) (add -1 in 2s complement)
    sta BG1VOFS
    sta BG1VOFS ; Set V offset Low, High, to FFFF for BG1
    lda #$FF    ; Scroll down 1 pixel (FF really 03FF 63) (add -1 in 2s complement)
    sta BG2VOFS
    sta BG2VOFS ; Set V offset Low, High, to FFFF for BG1
rts


.segment "RODATA"

; Turns out sprite MUST be 4bpp
; 2bpp will make a mess of everything as it does now
font_charset:
.incbin "assets/chars.pic"

tiles_basic_set:
.incbin "assets/basic_tileset.pic"
palette_basic_set:
.incbin "assets/basic_tileset.clr"

