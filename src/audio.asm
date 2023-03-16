; This is the audio program we want to transfer over
; We define it in the segment "SPCIMAGE"
; It is configured in lorom128.inc to be at bank 018000

.import spc_init, spc_end

; Do a simple audio transfer
; Transfer audio program

; $0200 is the Standard Data Transmission Region of the APU
; This is where we will transfer our program to.
; It is $7DFF bytes long (little under 32k)
START_ADDR = $0200

; calculate the number of bytes to transfer
SPC_SIZE = spc_end - spc_init

audio_init:
	; Save the program bank
	phb

	; Follow the Data Tansfer Procedure in Appendix D

	wait_for_apu_ready:

	; The APU needs to boot up and write AA,BB its registers

	lda #$AA
	cmp APUIO0
	bne wait_for_apu_ready

	lda #$BB
	cmp APUIO1
	bne wait_for_apu_ready

	; Main CPU writes back

	; Data Transfer Start Address
	lda #<START_ADDR
	sta APUIO2
	lda #>START_ADDR
	sta APUIO3

	; Non zero value
	lda #$01 
	sta APUIO1

	; Commit flag
	lda #$CC
	sta APUIO0

	; Data is now written to APU

	; Waiting for CC to be echoed in port 0
	wait_for_apu_to_reply:
	cmp APUIO0
	bne wait_for_apu_to_reply


	data_transfer_start:
	SPC_ADDRESS = $018000
	; Switch to the bank
	lda #^SPC_ADDRESS
	pha
	plb

	; Y is storing the offset to transfer
	; (Finish when we get to size)
	ldy #$0000

	; X is a counter 0..127 for data block sent
	ldx #$0000

	data_transfer_procedure:

	; write data to port1
	lda .loword(SPC_ADDRESS), y
	sta APUIO1
	; write len $00 to port 0
	txa 
	sta APUIO0

	data_transfer_reply:
	; wait for sound CPU to reply with the 0..127 to port 0
	; the accumulaor still holds the previous X value
	cmp APUIO0
	bne data_transfer_reply

	; Loop increase len by 1 each time.
	iny
	inx

	; We can not write a value of 00 until we are done
	; So we must check if we have wrapped around.
	; Actually the code is really weird. 
	; Instead it checks for 7F when I would have expected FF to wrap around.
	; Maybe theres a weird sign bit where 127 is max instead of 255

	txa
	cmp #$7F
	bne check_if_done
	; If were not done reset_tranfer_counter
	reset_tranfer_counter:
	; We must reset to non-zero value, so one.
	ldx #0001	


	
	check_if_done:
	; We need to check if we are done. If so goto complete
	cpy #SPC_SIZE
	beq data_transfer_complete

	; Otherwise continuing transmitting data
	bra data_transfer_procedure


	data_transfer_complete:

	; Put address to execute APU program in port 2/3
	lda #<START_ADDR
	sta APUIO2
	lda #>START_ADDR
	sta APUIO3

	; Write zero to start APU program
	stz APUIO1

	; Break	transfer cycle
    ; by adding two to previous port 0
	lda APUIO0
	adc #02
	sta APUIO0

	; Restore the program bank
	plb
rts


