; This file will be compiled to .byte statements using the rules in spc-ca65.
.include "spc-ca65.inc" 

; APU Addresses
; Ports to write to the DSP 
APU_DSP_CTRL = $F1
APU_DSP_ADR = $F2
APU_DSP_VAL = $F3
APU_DSP_PORT_0 = $F4
APU_DSP_PORT_1 = $F5
APU_DSP_PORT_2 = $F6
APU_DSP_PORT_3 = $F7
; Unused values
APU_DSP_TIMER_0 = $FA
APU_DSP_TIMER_1 = $FB
APU_DSP_TIMER_2 = $FC
APU_DSP_COUNTER_0 = $FD
APU_DSP_COUNTER_1 = $FE
APU_DSP_COUNTER_2 = $FF

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
DSP_KEY_ON = $4C
DSP_KEY_OFF = $5C
;...
DSP_FLAGS  = $6C
;...
DSP_NOISE_ON = $3D
DSP_ECHO_ON  = $4D

; Constants for variables
VOL_OFF = $00
VOL_MAX = $7F

; Note: SPC700 uses mov dst,src semantics


; Have a segment for the audio to be copied over
.segment "SPCIMAGE"

; Should be at $0200 in the APU 
; Align to 256 byte 
.align 256

; So I can find it quickly in the debugger
; .asciiz	"spcimagememory"

spc_init:

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
mov APU_DSP_VAL, #VOL_OFF

; Turn off the echo for all channels
mov APU_DSP_ADR, #DSP_ECHO_ON
mov APU_DSP_VAL, #$00


spc_start_noise:

; Set noise generator rate ;NCK
mov APU_DSP_ADR, #DSP_FLAGS
mov APU_DSP_VAL, #$2C ; ECEN off NCK=0C aka 200 Hz

; For voice 0:
; Set ADSR envelope
mov APU_DSP_ADR, #DSP_V0_ADSR_L
mov APU_DSP_VAL, #$FE ; DR=37ms AR=6ms
mov APU_DSP_ADR, #DSP_V0_ADSR_H
;mov APU_DSP_VAL, #$E9 ; 7 SL with 09 (5sec) SR
mov APU_DSP_VAL, #$FA ; 7 SL with 1A (110msec) SR


; Set voice volume L/R
mov APU_DSP_ADR, #DSP_V0_VOL_L
mov APU_DSP_VAL, #VOL_MAX
mov APU_DSP_ADR, #DSP_V0_VOL_R
mov APU_DSP_VAL, #VOL_MAX

; Turn on noise for voice 0
mov APU_DSP_ADR, #DSP_NOISE_ON
mov APU_DSP_VAL, #01

; Set Master volume for L/R
mov APU_DSP_ADR, #DSP_MASTER_VOL_L
mov APU_DSP_VAL, #VOL_MAX
mov APU_DSP_ADR, #DSP_MASTER_VOL_R
mov APU_DSP_VAL, #VOL_MAX

; Try to turn key on for voice 0
mov APU_DSP_ADR, #DSP_KEY_ON
mov APU_DSP_VAL, #01


; Let create a click-track like pulse with the time 

; I want to make a 120 bpm click track
; 120 bpm is 2 bps aka 1 beat every 500 ms

; T0 uses an 8 Khz clock
; That gives a max count value in the 4-bit up-counter of 512 ms.
; 512 ms is good enough for this purpose.
; When the value of the up-counter == timer register contents,
; the timer is cleared to $00

; We will use the 8Khz clock
; Using max counter $FF value (32ms)
; T0res 125us * 256ms cnt * 16 = rolls over every 512ms
; Reduce to 250 ($FA) to get exactly 500ms
; Each value counted will be 32ms * cnt

mov APU_DSP_TIMER_0, #$FA


; Clear the timers
mov APU_DSP_CTRL, #$00  ; Need to clear the timers first


; Enable the timer 
mov APU_DSP_CTRL, #$00  ; Need to clear the timers first
mov APU_DSP_CTRL, #$01 ; Start timer 0, ; Don't clear any ports


_apu_loop_forever:
  ; Our timer should be ticking
  ; If 4-bit up timer counter > 0: make noise note

  mov a, APU_DSP_COUNTER_0
  beq _apu_loop_forever

  ; timer has ticked, make some noise
  _apu_make_noise_note:
  ; Turn key on for voice 0 (noise channel)
  mov APU_DSP_ADR, #DSP_KEY_ON
  mov APU_DSP_VAL, #01

  _apu_loop_forever_continue:
  bra _apu_loop_forever

spc_end:
