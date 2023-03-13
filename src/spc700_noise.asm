; This file will be compiled to .byte statments using the rules in spc-ca65.
.include "spc-ca65.inc" 

; Ports to write to the DSP (APU Addresses)
APU_DSP_ADR = $F2
APU_DSP_VAL = $F3


; DSP Registers
DSP_V0_VOL_L = $00
DSP_V0_VOL_R = $01
; ...
DSP_V0_ADSR_L = $05
DSP_V0_ADSR_H = $06
;.. More voices

DSP_MASTER_VOL_L = $0C
DSP_MASTER_VOL_R = $1C
DSP_ECHO_VOL_L = $2C
DSP_ECHO_VOL_R = $3C
;...
DSP_FLAGS  = $6C
;...
DSP_NOISE_ON = $3D
DSP_ECHO_ON  = $4D


VOL_OFF = $00
VOL_MAX = $7F

; Note: SPC700 uses mov dst,src semantics


; Have a segment for the audio to be copied over
.segment "SPCIMAGE"

; Should be at $0200 in the APU 
; Align to 256 byte 
.align 256
prog_start:

_init:

; Set voice volume to 0 
mov APU_DSP_ADR, #DSP_V0_VOL_L
mov APU_DSP_VAL, #VOL_OFF
mov APU_DSP_ADR, #DSP_V0_VOL_R
mov APU_DSP_VAL, #VOL_OFF

; Mute everything and disable noise gen speed
mov APU_DSP_ADR, #DSP_FLAGS
mov APU_DSP_VAL, #%00100000 

; Turn off master volume
mov APU_DSP_ADR, #DSP_MASTER_VOL_L
mov APU_DSP_VAL, #VOL_OFF
mov APU_DSP_ADR, #DSP_MASTER_VOL_R
mov APU_DSP_VAL, #VOL_OFF

; Turn off Echo Volume
mov APU_DSP_ADR, #DSP_ECHO_VOL_L
mov APU_DSP_VAL, #VOL_OFF
mov APU_DSP_ADR, #DSP_ECHO_VOL_R
mov APU_DSP_VAL, #VOL_MAX

; Turn off the echo for all channels
mov APU_DSP_ADR, #DSP_ECHO_ON
mov APU_DSP_VAL, #$00


_start_noise:

; Set noise generator rate ;NCK
mov APU_DSP_ADR, #DSP_FLAGS
mov APU_DSP_VAL, #$2C ; ECEN off NCK=0C aka 200 Hz

; For voice 0:
; Set ADSR envelope
mov APU_DSP_ADR, #DSP_V0_ADSR_L
mov APU_DSP_VAL, #$FE
mov APU_DSP_ADR, #DSP_V0_ADSR_H
mov APU_DSP_VAL, #$FA

; Set voice volume L/R
mov APU_DSP_ADR, #DSP_V0_VOL_L
mov APU_DSP_VAL, #VOL_MAX
mov APU_DSP_ADR, #DSP_V0_VOL_R
mov APU_DSP_VAL, #VOL_MAX

; Set Master volume for L/R
mov APU_DSP_ADR, #DSP_MASTER_VOL_L
mov APU_DSP_VAL, #VOL_MAX
mov APU_DSP_ADR, #DSP_MASTER_VOL_R
mov APU_DSP_VAL, #VOL_MAX


_apu_loop_forever:
	bra _apu_loop_forever
