.zeropage
mBG1HOFS: .res 1, $00

.code

screen_scroll_left:
    lda mBG1HOFS
    ina
    sta mBG1HOFS   ; increment and update the Scroll position
rts

screen_scroll_right:
    lda mBG1HOFS
    dea
    sta mBG1HOFS   ; increment and update the Scroll position
rts

; Update the screen scroll register
.macro screen_scroll_vupdate
    lda mBG1HOFS
    sta BG1HOFS
    stz BG1HOFS     ; Write the position to the BG
.endmacro

