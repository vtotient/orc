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

PUSH0			equ P0.1

PUSH1			equ P0.4

PUSH2			equ P0.7

NO_HEAT         EQU P0.2

NO_COOL         EQU P0.5

P_out			equ P2.5

DEBUG			equ p3.6



bseg

One_Sec:		dbit 1

mf:				dbit 1

Auto:			dbit 1

Cool_on:		dbit 1

Heat_on:		dbit 1



dseg			at 30H

Count2ms:		ds 1

Result:			ds 2

x:				ds 4

y:				ds 4

bcd:			ds 5

Temp:			ds 2

Set_Temp:       ds 2

Temp_Upbound:	ds 2

Temp_Lowbound:	ds 2

Duty_Cycle:		ds 2

DC_BCD:			ds 2

Width_Count:	ds 2

Count10ms:		ds 1

ss_state:       ds 1
Disp1:		    ds 1
Disp2:		    ds 1
Disp3:	   	    ds 1 ; These correspond to the digits to be displayed 



CSEG

Timer0_Init:

    mov a, TMOD

    anl a, #0xf0 ; Clear the bits for timer 0

    orl a, #0x01 ; Configure timer 0 as 16-timer

    mov TMOD, a

    mov TH0, #high(TIMER0_RELOAD)

    mov TL0, #low(TIMER0_RELOAD)

    ; Set autoreload value

    mov TIMER0_RELOAD_H, #high(TIMER0_RELOAD)

    mov TIMER0_RELOAD_L, #low(TIMER0_RELOAD)

	mov Count2ms, #250

	clr One_Sec

    ; Enable the timer and interrupts

    setb ET0  ; Enable timer 0 interrupt

    setb TR0  ; Start timer 0

    ret

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
	lcall SS_State_Machine ; Adjust the pins of the microcontroller to display one digit at a time
	pop dph
	pop dpl
	pop psw
	pop acc
	reti
	
	
	
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



Timer0_Done_0:

	pop psw

	pop acc

	reti

Timer0_ISR:

	push acc

	push psw

	djnz Count10ms, Acquire_Temp

	mov Count10ms, #5

Acquire_Temp:

	djnz Count2ms, Timer0_Done_0

	mov Count2ms, #250
	
	cpl DEBUG

	clr CE_ADC

	mov R0, #00000001B ; Start bit:1

	lcall DO_SPI_G

	mov R0, #10000000B ; Single ended, read channel 0

	lcall DO_SPI_G

	mov a, R1 ; R1 contains bits 8 and 9

	anl a, #00000011B ; We need only the two least significant bits

	mov Result+1, a ; Save result high.

	mov R0, #55H ; It doesn't matter what we transmit...

	lcall DO_SPI_G

	mov Result, R1 ; R1 contains bits 0 to 7. Save result low.

	setb CE_ADC

	mov x+3, #0

	mov x+2, #0

	mov x+1, Result+1

	mov x+0, Result

	Load_Y(2505)

	lcall mul32

	Load_Y(100)

	lcall div32

	Load_Y(130)

	lcall add32

	Load_Y(2460)

	lcall add32
	
	load_y(100)
	
	lcall div32

	lcall hex2bcd

	mov Result+1, bcd+1

	mov Result+0, bcd+0

	Set_Cursor(2,1)

	Display_BCD(bcd+1)

	Display_BCD(bcd)

	Set_Cursor(2,5)

	Display_char(#'C')

Timer0_Done:

	pop psw

	pop acc

	reti


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





Init_line_0:	db 'CURR:           ', 0

Init_line_1:	db '                ', 0

AUTO_ICON:		db 'A:', 0

OFF:			db ' OFF', 0

COOL:			db 'COOL', 0

HEAT:			db 'HEAT', 0


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
    lcall Timer0_Init
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

    Send_Constant_String(#Init_line_0)

	Send_Constant_String(#Init_line_1)

	

Init_value:

	mov Set_Temp+1, #0x19

    mov Set_Temp+0, #0x50

    mov Temp_Upbound+1, #0x20

    mov Temp_Upbound+0, #0x50

    mov Temp_Lowbound+1, #0x18

    mov Temp_Lowbound+0, #0x50

    mov Duty_Cycle, #20

    clr Auto

	clr Cool_on

	clr Heat_on

	setb PUSH0

	setb PUSH1

	setb PUSH2

    

forever_loop:
	sjmp $

END

??????????????????????????????????????????