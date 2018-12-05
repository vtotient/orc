$MODLP51

org 0000H
   ljmp MainProgram
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
ljmp Serial_ISR

; Timer/Counter 2 overflow interrupt vector
org 0x002B
reti

$include(LCD_4bit.inc)


CLK  			EQU 22118400
BAUD 			equ 115200
BRG_VAL			equ (0x100-(CLK/(16*BAUD)))
LCD_RS 			equ P1.1
LCD_RW			equ P1.2
LCD_E  			equ P1.3
LCD_D4 			equ P3.2
LCD_D5 			equ P3.3
LCD_D6 			equ P3.4
LCD_D7 			equ P3.5

bseg
Tx_Ready:   	    dbit 1
line_number:		dbit 1

dseg				at 30H
echo_buff:			ds 1



CSEG

Serial_ISR:
    jnb TI, process_RI
    setb Tx_Ready
    clr TI
    reti
process_RI:
    mov a, SBUF
    clr RI
    ;jb Tx_Ready, echo
    ;jnb TI, $-4
    ;clr TI
echo:
    ;mov SBUF, a
display:
    mov echo_buff, a
    cpl line_number
    jb line_number, line2
    Set_Cursor(1,1)
    sjmp display_bits
line2:
    Set_Cursor(2,1)
display_bits:
    mov c, acc.7
    clr a
    mov acc.0, c
    orl a, #0x30
    lcall ?WriteData
    mov a, echo_buff
    mov c, acc.6
    clr a
    mov acc.0, c
    orl a, #0x30
    lcall ?WriteData
    mov a, echo_buff
    mov c, acc.5
    clr a
    mov acc.0, c
    orl a, #0x30
    lcall ?WriteData
    mov a, echo_buff
    mov c, acc.4
    clr a
    mov acc.0, c
    orl a, #0x30
    lcall ?WriteData
    mov a, echo_buff
    mov c, acc.3
    clr a
    mov acc.0, c
    orl a, #0x30
    lcall ?WriteData
    mov a, echo_buff
    mov c, acc.2
    clr a
    mov acc.0, c
    orl a, #0x30
    lcall ?WriteData
    mov a, echo_buff
    mov c, acc.1
    clr a
    mov acc.0, c
    orl a, #0x30
    lcall ?WriteData
    mov a, echo_buff
    mov c, acc.0
    clr a
    mov acc.0, c
    orl a, #0x30
    lcall ?WriteData
    Display_char(#'<')
    jb line_number, line_1
    Set_Cursor(2,9)
    sjmp clr_arrow
line_1:
    Set_Cursor(1,9)
clr_arrow:
	Display_char(#' ')
    reti
    
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
    setb ES ; Enable Serial Port interrupt
    setb PS ; Set serial port interrupt priority to high
    ret
;					1234567890123456
Init_line_0:	db 'Echo&bit examine', 0
Init_line_1:	db '                ', 0

MainProgram:
    mov SP, #7FH ; Set the stack pointer to the begining of idata
    lcall LCD_4bit
    lcall InitSerialPort
    ;lcall Timer0_Init
    setb EA
	Send_Constant_String(#Init_line_1)
	Send_Constant_String(#Init_line_1)
	

	sjmp $
END
