
$MODLP51

org 0000H

   ljmp MainProgram

; External interrupt 0 vector (not used in this code)

org 0x0003

reti



; Timer/Counter 0 overflow interrupt vector

org 0x000B

ljmp Timer0_ISR



; External interrupt 1 vector (not used in this code)

org 0x0013

reti


	
; Timer/Counter 1 overflow interrupt vector (not used in this code)

org 0x001B

reti



; Serial port receive/transmit interrupt vector (not used in this code)

org 0x0023

reti



; Timer/Counter 2 overflow interrupt vector

org 0x002B
ljmp Timer2_ISR



$include(math32.inc)

$include(LCD_4bit.inc)





TIMER0_RELOAD_L DATA 0xf2

TIMER1_RELOAD_L DATA 0xf3

TIMER0_RELOAD_H DATA 0xf4

TIMER1_RELOAD_H DATA 0xf5

CLK  			EQU 22118400

TIMER0_RATE     EQU 500

TIMER0_RELOAD   EQU ((65536-(CLK/TIMER0_RATE)))

BAUD 			equ 115200

BRG_VAL			equ (0x100-(CLK/(16*BAUD)))

CE_ADC 			EQU P2.0

MY_MOSI 		EQU P2.1

MY_MISO 		EQU P2.2

MY_SCLK 		EQU P2.3 

; Seven Segment Wiring
EN_DIG_1 EQU P2.4
EN_DIG_2 EQU P4.5
EN_DIG_3 EQU P2.6

SS_A	 EQU P0.7
SS_B	 EQU P0.6
SS_C	 EQU P0.5
SS_D	 EQU P0.4
SS_E	 EQU P0.3
SS_F	 EQU P0.2
SS_G	 EQU P0.1

; This is for the seven segment display
SS_0    EQU #0x3f
SS_1	EQU #0x06
SS_2	EQU #0x5b
SS_3	EQU #0x4f
SS_4	EQU #0x66
SS_5 	EQU #0x6d
SS_6	EQU #0x7d
SS_7 	EQU #0x07
SS_8	EQU #0x7f
SS_9 	EQU #0x67
SS_Err	EQU #0x79 ; This is for debugging purposes

; Timer 2 
TIMER2_RATE   EQU 1000 
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))

LCD_RS 			equ P1.1

LCD_RW			equ P1.2

LCD_E  			equ P1.3

LCD_D4 			equ P3.2

LCD_D5 			equ P3.3

LCD_D6 			equ P3.4

LCD_D7 			equ P3.5

P_out			equ P2.5

DEBUG			equ p3.6



bseg

One_Sec:		dbit 1

mf:				dbit 1

Count2ms:		dbit 1

Probe_Flag:		dbit 1



dseg			at 30H

Result:			ds 2

x:				ds 4

y:				ds 4

bcd:			ds 5

Temp:			ds 2

Calibrated_Result:	ds 2

ss_state:       ds 1
Disp1:		    ds 1
Disp2:		    ds 1
Disp3:	   	    ds 1 ; These correspond to the digits to be displayed 
Probe1_Temp_Sample1:	ds 2
Probe1_Temp_Sample2:	ds 2
Probe2_Temp_Sample1:	ds 2
Probe2_Temp_Sample2:	ds 2
Probe3_Temp_Sample1:	ds 2
Probe4_Temp_Sample2:	ds 2
Probe1_Temp:			ds 2
Probe2_Temp:			ds 2
Probe3_Temp:			ds 2



CSEG
;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 2                     ;
;---------------------------------;
Timer2_Init:
	push acc
	push psw 
	mov T2CON, #0 ; Stop timer/counter.  Autoreload mode.
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	; Set the reload value
	mov RCAP2H, #high(TIMER2_RELOAD)
	mov RCAP2L, #low(TIMER2_RELOAD)
	; Init One millisecond interrupt counter.  It is a 16-bit variable made with two 8-bit parts
	
	; Enable the timer and interrupts
    setb ET2  ; Enable timer 2 interrupt
    setb TR2  ; Enable timer 2
    pop psw
    pop acc
	ret

;---------------------------------;
; ISR for timer 2                 ;
;---------------------------------;
Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
	
	; The two registers used in the ISR must be saved in the stack
	push acc
	push psw
	push dpl
	push dph
	cpl Count2ms
	jb Count2ms, first_sample
	ljmp display_temp
first_sample:
	Probe_Temp(#10000000B,Probe1_Temp_Sample1,2490,35,1)	
	Probe_Temp(#10010000B,Probe2_Temp_Sample1,2492,0,0)		;needs last 2 parameters tested
	Probe_Temp(#10100000B,Probe3_Temp_Sample1,2485,50,1)		;needs last 2 parameters tested

;	Probe_Temp(#10000000B,Probe3_Temp,2475,0,0)	
;	Probe_Temp(#10010000B,Probe2_Temp,2475,0,0)		;needs last 2 parameters tested
;	Probe_Temp(#10100000B,Probe1_Temp,2475,0,0)		;needs last 2 parameters tested

	lcall clear_xy
	mov x+1, Probe3_Temp_Sample2+1
	mov x+0, Probe3_Temp_Sample2+0
	Load_Y(99)
	lcall mul32
	mov y+1, Probe3_Temp_Sample1+1
	mov y+0, Probe3_Temp_Sample1+0
	lcall add32
	;lcall add32
	Load_Y(100)
	lcall div32
	mov Probe3_Temp_Sample2+1, x+1
	mov Probe3_Temp_Sample2+0, x+0
	lcall clear_xy
	mov x+1, Probe2_Temp_Sample2+1
	mov x+0, Probe2_Temp_Sample2+0
	Load_Y(99)
	lcall mul32
	mov y+1, Probe2_Temp_Sample1+1
	mov y+0, Probe2_Temp_Sample1+0
	lcall add32
	;lcall add32
	Load_Y(100)
	lcall div32
	mov Probe2_Temp_Sample2+1, x+1
	mov Probe2_Temp_Sample2+0, x+0
	lcall clear_xy
	mov x+1, Probe1_Temp_Sample2+1
	mov x+0, Probe1_Temp_Sample2+0
	Load_Y(99)
	lcall mul32
	mov y+1, Probe1_Temp_Sample1+1
	mov y+0, Probe1_Temp_Sample1+0
	lcall add32
	;lcall add32
	Load_Y(100)
	lcall div32
	mov Probe1_Temp_Sample2+1, x+1
	mov Probe1_Temp_Sample2+0, x+0
	
	
	djnz Count2ms, display_temp
	mov Count2ms, #250
	
	;cpl P3.6
	mov Probe1_Temp+1, Probe1_Temp_Sample2+1
	mov Probe1_Temp+0, Probe1_Temp_Sample2+0
	mov Probe2_Temp+1, Probe2_Temp_Sample2+1
	mov Probe2_Temp+0, Probe2_Temp_Sample2+0
	mov Probe3_Temp+1, Probe3_Temp_Sample2+1
	mov Probe3_Temp+0, Probe3_Temp_Sample2+0
	
	lcall Calibrate_Temp
	
display_temp:
	lcall SS_State_Machine ; Adjust the pins of the microcontroller to display one digit at a time
	pop dph
	pop dpl
	pop psw
	pop acc
	reti
	
	
;--------------------;
;Calibrate_Temp
;--------------------;
Calibrate_Temp: 
	Compare_Probes(Probe1_Temp,Probe2_Temp,5)
	jnb Probe_Flag, Probes_1and2_Invalid
	Place_Calibrated_Temp(Probe1_Temp,Probe2_Temp)
	ljmp Calibration_Complete
Probes_1and2_Invalid:	;if 1,2 invalid, check 1,3 or 2,3
	;error 4

	Compare_Probes(Probe1_Temp,Probe3_Temp,5)
	jnb Probe_Flag, Probes_1and3_Invalid
	Place_Calibrated_Temp(Probe1_Temp,Probe3_Temp)
	ljmp Calibration_Complete
Probes_1and3_Invalid:	;if 1,3 invalid, check 2,3

	Compare_Probes(Probe2_Temp,Probe3_Temp,3)
	jnb Probe_Flag, Probes_2and3_Invalid
	Place_Calibrated_Temp(Probe2_Temp,Probe3_Temp)
	ljmp Calibration_Complete
Probes_2and3_Invalid:
;	;if the code gets here, this is an error between all probes, take probe1 value
	mov Calibrated_Result+1, Probe1_Temp+1
	mov Calibrated_Result+0, Probe1_Temp+0
	
	
Calibration_Complete:
	mov x+3, #0
	mov x+2, #0
	mov x+1, Calibrated_Result+1
	mov x+0, Calibrated_Result+0
	Load_Y(100)		; put desired tempurature in Temp
	lcall div32
	mov Temp+1, x+1
	mov Temp+0, x+0
	ret
	
; Table for the hex display:
HEX_7SEG: DB 0xC0, 0xF9, 0xA4, 0xB0, 0x99
		  DB 0x92, 0x82, 0xF8, 0x80, 0x90 

		  	  	
; State machine for 7-segment displays starts here
; Turn all displays off
SS_State_Machine:
	mov dptr, #HEX_7SEG
	mov a, result
	anl a, #0x0f
	movc a, @a+dptr
	mov disp1, a
	mov a, result
	swap a
	anl a, #0x0f
	movc a, @a+dptr
	mov disp2, a
	mov a, result+1
	movc a, @a+dptr
	mov disp3, a
	
	setb EN_DIG_1
	setb EN_DIG_2
	setb EN_DIG_3
	mov  a, ss_state
	
state0:
	cjne a, #0, state1
	mov a, disp1
	lcall load_segments
	clr EN_DIG_1
	inc ss_state
	sjmp state_done
state1:
	cjne a, #1, state2
	mov a, disp2
	lcall load_segments
	clr EN_DIG_2
	inc ss_state
	sjmp state_done
state2:
	cjne a, #2, state_reset
	mov a, disp3
	lcall load_segments
	clr EN_DIG_3
	mov ss_state, #0
	sjmp state_done
state_reset:
	mov ss_state, #0
state_done:
	ret


; Pattern to load passed in acc
load_segments:
	mov c, acc.0
	mov SS_A, c
	mov c, acc.1
	mov SS_B, c
	mov c, acc.2
	mov SS_C, c
	mov c, acc.3
	mov SS_D, c
	mov c, acc.4
	mov SS_E, c
	mov c, acc.5
	mov SS_F, c
	mov c, acc.6
	mov SS_G, c 
	ret





INIT_SPI:

	setb MY_MISO ; Make MISO an input pin

	clr MY_SCLK ; For mode (0,0) SCLK is zero

	ret



DO_SPI_G:

	push acc

	mov R1, #0 ; Received byte stored in R1

	mov R2, #8 ; Loop counter (8-bits)

DO_SPI_G_LOOP:

	mov a, R0 ; Byte to write is in R0

	rlc a ; Carry flag has bit to write

	mov R0, a

	mov MY_MOSI, c

	setb MY_SCLK ; Transmit

	mov c, MY_MISO ; Read received bit

	mov a, R1 ; Save received bit in R1

	rlc a

	mov R1, a

	clr MY_SCLK

	djnz R2, DO_SPI_G_LOOP

	pop acc

	ret





; Set low the enable pins and pull up the driving pins
INIT_SS:
	mov AUXR, #0x01
	clr EN_DIG_1
	clr EN_DIG_2
	clr EN_DIG_3 ; Disable the digits
	
	setb SS_A
	setb SS_B
	setb SS_C
	setb SS_D
	setb SS_E
	setb SS_F
	setb SS_G
	
	ret

MainProgram:

    mov SP, #7FH ; Set the stack pointer to the begining of idata

    setb CE_ADC

    lcall INIT_SPI

    lcall LCD_4bit

    lcall Timer2_Init ; Some initializations
    lcall INIT_SS
    mov P0M0, #0
    mov P0M1, #0 
    mov P4M0, #0
    mov P4M1, #0
    mov P2M0, #0
    mov P2M1, #0 ; set pins in biconditional mode
    Mov AUXR, #00000001B
    mov ss_state, #0x00

    setb EA

    mov P0M0, #0

    mov P0M1, #0

	

Init_value:

    

forever_loop:
	sjmp $

END

??????????????????????????????????????????
