.code
; Assumes Tile Data is loaded at $500 or $50 in VRAM
; Loads 4 tiles per row
level_basic_tile_load_tilemap:
    lda #V_INC_1
    sta VMAIN        ; Single Inc
 
    ldx #$0400      ;#($0400 + $0 + $0 * $20) ; screen position 0 
    stx VMADDL

    ldx #$08        ; Loop 8 x 4 times (unrolled)
    ldy #$1050      ; 10 for color palette 4, number 50 for basic tile set
    @do_row:
        jsr _fill_row_with_tiles
        jsr _fill_row_with_tiles
        jsr _fill_row_with_tiles
        jsr _fill_row_with_tiles
        iny
        dex 
    bne @do_row
rts

; Assume VMADDL is currently set to proper position autoinc-1
; Need Y to be the tile data - attr+name
; Modifies A
_fill_row_with_tiles:
    ; Write Y 32 times.
    lda #$4
    @loop_row:
        sty VMDATAL
        sty VMDATAL
        sty VMDATAL
        sty VMDATAL
        sty VMDATAL
        sty VMDATAL
        sty VMDATAL
        sty VMDATAL
        dea
    bne @loop_row
rts
