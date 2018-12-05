$NOLIST
$MODLP51
$LIST

TIMER0_RELOAD_L DATA 0xf2
TIMER1_RELOAD_L DATA 0xf3
TIMER0_RELOAD_H DATA 0xf4
TIMER1_RELOAD_H DATA 0xf5

CLK           EQU 22118400 ; Microcontroller system crystal frequency in Hz
TIMER1_RATE   EQU 4096     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER1_RELOAD EQU ((65536-(CLK/TIMER1_RATE)))
TIMER2_RATE   EQU 1000     ; 1000Hz, for a timer tick of 1ms
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))

SOUND_OUT     equ P3.7

BUTTON_ONE equ P4.5
BUTTON_TWO equ P2.5
BUTTON_THREE equ P2.6

org 0x0000
    ljmp main
	
org 0x001B
	ljmp Timer1_ISR
	
org 0x002B
	ljmp Timer2_ISR

dseg at 0x30
Count_one: ds 2
Count_two: ds 2
Count_three: ds 2

bseg
flag_one: dbit 1
flag_two: dbit 1
flag_three: dbit 1

cseg
LCD_RS equ P1.1
LCD_RW equ P1.2
LCD_E  equ P1.3
LCD_D4 equ P3.2
LCD_D5 equ P3.3
LCD_D6 equ P3.4
LCD_D7 equ P3.5

$NOLIST
$include(LCD_4bit.inc)
$LIST

;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 1                    ;
;---------------------------------;
Timer1_Init:
	mov a, TMOD
	anl a, #0x0f
	orl a, #0x10
	mov TMOD, a
	mov TH1, #high(TIMER1_RELOAD)
	mov TL1, #low(TIMER1_RELOAD)
	mov TIMER1_RELOAD_H, #high(TIMER1_RELOAD)
	mov TIMER1_RELOAD_L, #low(TIMER1_RELOAD)
    setb ET1
	ret

;---------------------------------;
; ISR for timer 1.                ;
;---------------------------------;
Timer1_ISR:
	cpl SOUND_OUT
	reti

;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 2                     ;
;---------------------------------;
Timer2_Init:
	mov T2CON, #0
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	mov RCAP2H, #high(TIMER2_RELOAD)
	mov RCAP2L, #low(TIMER2_RELOAD)
	clr a
    setb ET2
    setb TR2
	ret

;---------------------------------;
; ISR for timer 2                 ;
;---------------------------------;
Timer2_ISR:
	clr TF2
	push acc
	push psw
	
Inc_Count_one:
	jnb flag_one, Inc_Count_two
	inc Count_one+0
	mov a, Count_one+0
	jnz Inc_Count_two
	inc Count_one+1
	
Inc_Count_two:
	jnb flag_two, Inc_Count_three
	inc Count_two+0
	mov a, Count_two+0
	jnz Inc_Count_three
	inc Count_two+1

Inc_Count_three:
	jnb flag_three, Check_Count_one
	inc Count_three+0
	mov a, Count_three+0
	jnz Check_Count_one
	inc Count_three+1

Check_Count_one:
	mov a, Count_one+0
	cjne a, #low(300), Check_Count_two
	mov a, Count_one+1
	cjne a, #high(300), Check_Count_two
	
	cpl TR1
	clr flag_one
	clr a
	mov Count_one+0, a
	mov Count_one+1, a
	
Check_Count_two:
	mov a, Count_two+0
	cjne a, #low(1000), Check_Count_three
	mov a, Count_two+1
	cjne a, #high(1000), Check_Count_three

	cpl TR1
	clr flag_two
	clr a
	mov Count_two+0, a
	mov Count_two+1, a
	
Check_Count_three:
	mov a, Count_three+0
	cjne a, #low(150), Check_Count_three_2
	mov a, Count_three+1
	cjne a, #high(150), Check_Count_three_2
	cpl TR1
Check_Count_three_2:
	mov a, Count_three+0
	cjne a, #low(300), Check_Count_three_3
	mov a, Count_three+1
	cjne a, #high(300), Check_Count_three_3

	; If you want to change the pitch
	; mov TH1, #high(65536-(CLK/(2637*2)))
	; mov TL1, #low(65536-(CLK/(2637*2)))
	; mov TIMER1_RELOAD_H, #high(65536-(CLK/(2637*2)))
	; mov TIMER1_RELOAD_L, #low(65536-(CLK/(2637*2)))

	cpl TR1
Check_Count_three_3:
	mov a, Count_three+0
	cjne a, #low(450), Check_Count_three_4
	mov a, Count_three+1
	cjne a, #high(450), Check_Count_three_4
	cpl TR1
Check_Count_three_4:
	mov a, Count_three+0
	cjne a, #low(600), Check_Count_three_5
	mov a, Count_three+1
	cjne a, #high(600), Check_Count_three_5
	cpl TR1
Check_Count_three_5:
	mov a, Count_three+0
	cjne a, #low(750), Check_Count_three_6
	mov a, Count_three+1
	cjne a, #high(750), Check_Count_three_6
	cpl TR1
Check_Count_three_6:
	mov a, Count_three+0
	cjne a, #low(900), Check_Count_three_7
	mov a, Count_three+1
	cjne a, #high(900), Check_Count_three_7
	cpl TR1
Check_Count_three_7:
	mov a, Count_three+0
	cjne a, #low(1050), Check_Count_three_8
	mov a, Count_three+1
	cjne a, #high(1050), Check_Count_three_8
	cpl TR1
Check_Count_three_8:
	mov a, Count_three+0
	cjne a, #low(1200), Check_Count_three_9
	mov a, Count_three+1
	cjne a, #high(1200), Check_Count_three_9
	cpl TR1
Check_Count_three_9:
	mov a, Count_three+0
	cjne a, #low(1350), Check_Count_three_10
	mov a, Count_three+1
	cjne a, #high(1350), Check_Count_three_10
	cpl TR1
Check_Count_three_10:
	mov a, Count_three+0
	cjne a, #low(1500), Check_Count_three_11
	mov a, Count_three+1
	cjne a, #high(1500), Check_Count_three_11
	cpl TR1
Check_Count_three_11:
	mov a, Count_three+0
	cjne a, #low(1650), Timer2_ISR_done
	mov a, Count_three+1
	cjne a, #high(1650), Timer2_ISR_done
	cpl TR1
	
	clr flag_three
	clr a
	mov Count_three+0, a
	mov Count_three+1, a
	
Timer2_ISR_done:
	pop psw
	pop acc
	reti

;---------------------------------;
; Main program. Includes hardware ;
; initialization and 'forever'    ;
; loop.                           ;
;---------------------------------;
main:
    mov SP, #0x7F
    lcall Timer1_Init
    lcall Timer2_Init
    setb EA
    lcall LCD_4BIT
	
loop:
	jb BUTTON_ONE, check_button_two
	Wait_Milli_Seconds(#100)
	jb BUTTON_ONE, check_button_two
	
	clr a
	mov Count_one+0, a
	mov Count_one+1, a
	setb flag_one
	cpl TR1
	
check_button_two:
	jb BUTTON_TWO, check_button_three
	Wait_Milli_Seconds(#100)
	jb BUTTON_TWO, check_button_three
	
	clr a
	mov Count_two+0, a
	mov Count_two+1, a
	setb flag_two
	cpl TR1
	
check_button_three:
	jb BUTTON_THREE, loop
	Wait_Milli_Seconds(#100)
	jb BUTTON_THREE, loop

	clr a
	mov Count_three+0, a
	mov Count_three+1, a
	setb flag_three
	cpl TR1
	
	ljmp loop
END
