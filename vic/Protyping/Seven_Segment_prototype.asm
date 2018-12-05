; Initial layout-Credit: Dr. Jesus C. Fraga 
$NOLIST
$MODLP51
$LIST

; Reset vector
org 0x0000
    ljmp Main
       
; External interrupt 0 vector (not used in this code)
org 0x0003
	reti

; Timer/Counter 0 overflow interrupt vector
org 0x000B
	reti

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

; Include files
$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros-Credit: Dr. Jesus C. Fraga
$include(math32.inc) ; A library of 32bit math functions and utility macros-Credit: Dr. Jesus C. Fraga
$LIST

; Symbolic constants
CLK     EQU 22118400
BAUD    EQU 115200
BRG_VAL EQU (0x100-(CLK/(16*BAUD)))

; LCD hardware wiring
LCD_RS EQU P1.1
LCD_RW EQU P1.2
LCD_E  EQU P1.3
LCD_D4 EQU P3.2
LCD_D5 EQU P3.3
LCD_D6 EQU P3.4
LCD_D7 EQU P3.5

; ADC hardware wiring
CE_ADC  EQU P2.0
MY_MOSI EQU P2.1
MY_MISO EQU P2.2
MY_SCLK EQU P2.3


; Timer 2 
TIMER2_RATE   EQU 1000 
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))

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

; Direct access variables (address 0x30 - 0x7F) used by math32 library
dseg at 30H
x:      ds 4
y:      ds 4
bcd:    ds 5 ; this is the bcd for temperature
Result: ds 2
buffer: ds 30

ss_state:     ds 1
Disp1:		  ds 1
Disp2:		  ds 1
Disp3:	   	  ds 1 ; These correspond to the digits to be displayed 

			       
bseg
mf: dbit 1


cseg
DEBUG:
	Set_Cursor(2,5)
	Display_char(#33)
	sjmp DEBUG
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
	mov a, bcd
	anl a, #0x0f
	movc a, @a+dptr
	mov disp1, a
	mov a, bcd
	swap a
	anl a, #0x0f
	movc a, @a+dptr
	mov disp2, a
	mov disp3, #0xff ; Decode bcd to seven segment
	
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



; Convert the voltage signal to a temperature in Celsius 
Convertor:
	mov x+0, Result + 0
	mov x+1, Result + 1
	mov x+2, #0x00
	mov x+3, #0x00
	
	Load_Y(410)
	lcall mul32 
	Load_Y(1023)
	lcall div32
	
	Load_Y(273)
	lcall sub32
	lcall hex2bcd
	ret

; Some constant messages to be displayed
newline:
    DB  ' ', '\r', '\n', 0
Screen_Format:
	db 'Temperature:', '\r', '\n', 0
LCD_Message:
	db 'Temperature:', 0  
   
; Send data to putty to be displayed or processed
Execute_Result:
	lcall Convertor
	
	Send_BCD(bcd) 	 ; Send to PuTTy 
	
	mov DPTR, #newline
	lcall sendstring

	ret

; Configure the serial port and baud rate
InitSerialPort:
    ; Since the reset button bounces, we need to wait a bit before
    ; sending messages, otherwise we risk displaying gibberish!
    mov R1, #222
    mov R0, #166
    djnz R0, $   ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, $-4 ; 22.51519us*222=4.998ms
    
    ; Now we can proceed with the configuration
	orl	PCON,#0x80
	mov	SCON,#0x52
	mov	BDRCON,#0x00
	mov	BRL,#BRG_VAL
	mov	BDRCON,#0x1E ; BDRCON=BRR|TBCK|RBCK|SPD;
    ret

; Send a character using the serial port
putchar:
    jnb TI, putchar
    clr TI
    mov SBUF, a
    ret

; Send a constant-zero-terminated string using the serial port
SendString:
    clr A
    movc A, @A+DPTR
    jz SendStringDone
    lcall putchar
    inc DPTR
    sjmp SendString

SendStringDone:
    ret ; returns to main, not SendString

; Initialize the SPI. This is done in Main
INIT_SPI:
	setb MY_MISO ; Make MISO an input pin
	clr MY_SCLK  ; Mode 0,0 default
	ret

; Bit-Bang-Credit: Dr. Jesus C. Fraga
; Used for transmiting data between the MCP chip and the Atmel chip
DO_SPI_G:
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
	ret

; More comunication between chips. This routine calls the bitbang and handles the transmition 
; of data. 
Fetch_Voltage:
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
	lcall Wait_Second
	lcall Execute_Result
	Set_Cursor(2,5) 
	Display_BCD(bcd) ; Display on LCD 
	ret

; Used to create a delay of one second
Wait_Second:
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
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

; Main program. Contains the loop that fetches voltage
Main:
    mov SP, #7FH ; Set the stack pointer to the begining of idata
    lcall LCD_4bit
    lcall InitSerialPort
    lcall INIT_SPI 
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
    Set_Cursor(1,1)
    Send_Constant_String(#LCD_Message) ; Display a constant string on LCD
    Set_Cursor(2,8)
    Display_char(#67)
    setb EA ; Enable global interrupts
   
Fetch_Voltage_Loop:

	lcall Fetch_Voltage
	sjmp Fetch_Voltage_Loop
    
END