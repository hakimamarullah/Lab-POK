;====================================================================
; Processor		: ATmega8515
; Compiler		: AVRASM
;====================================================================

;====================================================================
; DEFINITIONS
;====================================================================

.include "m8515def.inc"
.def temp = r16 		; temporary register
.def EW = r23 			; for PORTA
.def PB = r24 			; for PORTB
.def A  = r25
.def msg_counter = r20
.def lcd_counter = r21

;====================================================================
; RESET and INTERRUPT VECTORS
;====================================================================

.org $00
rjmp MAIN
.org $01
rjmp BUTTON

;====================================================================
; CODE SEGMENT
;====================================================================

MAIN:

INIT_STACK:
	ldi temp, low(RAMEND)
	ldi temp, high(RAMEND)
	out SPH, temp

INIT_INTERRUPT:
	ldi temp,0b00000010
	out MCUCR,temp
	ldi temp,0b01000000
	out GICR,temp
	sei

rcall INIT_LCD

EXIT:
	rjmp EXIT

INPUT_TEXT:
	ldi ZH,high(2*NPM)	; Load high part of byte address into ZH
	ldi ZL,low(2*NPM)	; Load low part of byte address into ZL
	cpi msg_counter, 1
	breq LOADBYTE

	rjmp LOADBYTE

INIT_LCD_MAIN:
	rcall INIT_LCD

	ser temp
	out DDRA,temp 		; Set port A as output
	out DDRB,temp 		; Set port B as output

	rjmp INPUT_TEXT

LOADBYTE:
	lpm 				; Load byte from program memory into r0
	tst r0 				; Check if we've reached the end of the message
	breq END_LCD	 	; If so, quit

	mov A, r0 			; Put the character onto Port B
	rcall WRITE_TEXT
	adiw ZL,1 			; Increase Z registers
	rjmp LOADBYTE

END_LCD:
	ret

INIT_LCD:
	cbi PORTA,1 	; CLR RS
	ldi PB,0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTB,PB
	sbi PORTA,0 	; SETB EN
	cbi PORTA,0 	; CLR EN
	rcall DELAY_01

	cbi PORTA,1 	; CLR RS
	ldi PB,$0E 		; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORTB,PB
	sbi PORTA,0 	; SETB EN
	cbi PORTA,0 	; CLR EN
	rcall DELAY_01

	rcall CLEAR_LCD ; CLEAR LCD

	cbi PORTA,1 	; CLR RS
	ldi PB,$06		; MOV DATA,0x06 --> increase cursor, display scroll OFF
	out PORTB,PB
	sbi PORTA,0 	; SETB EN
	cbi PORTA,0 	; CLR EN
	rcall DELAY_01
	ret

CLEAR_LCD:
	cbi PORTA,1 	; CLR RS
	ldi PB,$01 		; MOV DATA,0x01
	out PORTB,PB
	sbi PORTA,0 	; SETB EN
	cbi PORTA,0 	; CLR EN
	rcall DELAY_01
	ret

WRITE_TEXT:
	inc lcd_counter
	cpi lcd_counter,4
	breq NEW_LINE

	sbi PORTA,1 	; SETB RS
	out PORTB, A
	sbi PORTA,0 	; SETB EN
	cbi PORTA,0 	; CLR EN
	rcall DELAY_01
	ret

NEW_LINE:
	cbi PORTA,1
	ldi PB,$C0
	out PORTB,PB
	sbi PORTA,0
	cbi PORTA,0
	rcall DELAY_01

	sbi PORTA,1 	; SETB RS
	out PORTB, A
	sbi PORTA,0 	; SETB EN
	cbi PORTA,0 	; CLR EN
	rcall DELAY_01
	ret

BUTTON:
	inc msg_counter
	cpi msg_counter, 2
	brlt RESET_LCD_COUNTER
	reti

RESET_LCD_COUNTER:
	ldi lcd_counter,0 ;
	ldi msg_counter,0
	rcall INIT_LCD_MAIN
	reti

;SOURCE : LAB 5 POK 2020
;====================================================================
; DELAYS	[ Generated by delay loop calculator at	  ]
; 			[ http://www.bretmulvey.com/avrdelay.html ]
;====================================================================

DELAY_00:				; Delay 4 000 cycles
						; 500us at 8.0 MHz	
	    ldi  r18, 6
	    ldi  r19, 49
	L0: dec  r19
	    brne L0
	    dec  r18
	    brne L0
	ret

DELAY_01:				; DELAY_CONTROL 40 000 cycles
						; 5ms at 8.0 MHz
	    ldi  r18, 52
	    ldi  r19, 242
	L1: dec  r19
	    brne L1
	    dec  r18
	    brne L1
	    nop
	ret

DELAY_02:				; Delay 160 000 cycles
						; 20ms at 8.0 MHz
	    ldi  r18, 208
	    ldi  r19, 202
	L2: dec  r19
	    brne L2
	    dec  r18
	    brne L2
	    nop
	ret

;====================================================================
; DATA
;====================================================================

NPM:
.db "NPM1906293051",0