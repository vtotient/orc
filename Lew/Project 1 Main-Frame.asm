;Project 1 Main-Frame
;Authors- Lewis Mason, 

$MODLP51

; Reset vector
org 0x0000
    ljmp mainprogram


; External interrupt 0 vector (not used in this code)
org 0x0003
	reti

; Timer/Counter 0 overflow interrupt vector
org 0x000B
	;ljmp Timer0_ISR
	reti

; External interrupt 1 vector (not used in this code)
org 0x0013
	reti

; Timer/Counter 1 overflow interrupt vector (not used in this code)
org 0x001B
	ljmp Timer1_ISR

; Serial port receive/transmit interrupt vector
org 0x0023 
	ljmp Serial_ISR
	reti
	
; Timer/Counter 2 overflow interrupt vector
org 0x002B
	ljmp Timer2_ISR
	
   ;current1234
 
$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$include(Lewis_Lib.inc); A library of macros related to the project
$include(math32.inc); A library of macros for doing math operations
$include(serialthermo.inc)	; Contains functions that handle serial port communications
$include(Timer2_ISR.inc)	; Contains the timer 2 isr, which uses multiple probes to recieve the correct temp
$include(alarm_subroutines.inc) ; Functions for checking and triggering alarms
$include(ResetDisplay.inc)		;Contains the function that displays the reset screen
$LIST

TIMER0_RELOAD_L DATA 0xf2
TIMER1_RELOAD_L DATA 0xf3
TIMER0_RELOAD_H DATA 0xf4
TIMER1_RELOAD_H DATA 0xf5

CLK           EQU 22118400 ; Microcontroller system crystal frequency in Hz
TIMER0_RATE   EQU 500     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER0_RELOAD EQU ((65536-(CLK/TIMER0_RATE)))
TIMER1_RATE   EQU 4096     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER1_RELOAD EQU ((65536-(CLK/TIMER1_RATE)))
TIMER2_RATE   EQU 500     ; 1000Hz, for a timer tick of 1ms
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))

BAUD		  equ 115200
BRG_VAL		  equ (0x100-(CLK/(16*BAUD)))
ROOM_T		  equ 2450

SOUND_OUT     equ P3.7

Dseg at 30H
Current_Preset: 			ds 1	;1 byte to be used globally, determining the current preset

Soak_Settings_T_hex:		ds 1
Soak_Settings_Temp_hex:		ds 1
Soak_Preset1_T_hex: 		ds 1
Soak_Preset2_T_hex: 		ds 1
Soak_Preset3_T_hex: 		ds 1
Soak_Preset1_Temp_hex: 		ds 1
Soak_Preset2_Temp_hex: 		ds 1
Soak_Preset3_Temp_hex: 		ds 1

Reflow_Settings_T_hex:		ds 1
Reflow_Preset1_T_hex: 		ds 1
Reflow_Preset2_T_hex: 		ds 1
Reflow_Preset3_T_hex: 		ds 1
Reflow_Settings_Temp_hex:	ds 1
Reflow_Preset1_Temp_hex: 	ds 1
Reflow_Preset2_Temp_hex: 	ds 1
Reflow_Preset3_Temp_hex: 	ds 1

;when the process starts, the current values of temp and time settings get put into the below,
Soak_Start_T_hex: 			ds 1
Reflow_Start_T_hex: 		ds 1
Soak_Start_Temp_hex: 		ds 1
Reflow_Start_Temp_hex: 		ds 1
;other variables used during runtime
oven_state: 				ds 1	;contains the current state of the running process
state_flag_counter:			ds 1 	;used to determine what is displayed for the current state on the lcd

;variables that are used for math functions
x:							ds 4
y:							ds 4	
bcd:						ds 5
BCD_counter: 				ds 2	; The BCD counter incrememted in the ISR and displayed in the main loop
BCD_state_counter: 			ds 2	; The BCD counter incrememted in the ISR and displayed in the main loop
Count1ms:    				ds 2 	; Used to determine when half second has passed

Probe1_Temp:				ds 2
Probe2_Temp:				ds 2
Probe3_Temp:				ds 2
Room_Temp:					ds 2
Temp: 						ds 2 	; The current bitbanged-Temperature, stored as a binary number
Set_Temp: 					ds 1 	; The temp used to transition states
Probe3_Temp_Sample1:		ds 2
Probe3_Temp_Sample2:		ds 2
Probe2_Temp_Sample1:		ds 2
Probe2_Temp_Sample2:		ds 2
Probe1_Temp_Sample1:		ds 2
Probe1_Temp_Sample2:		ds 2
;NOTE: Put the desired tempurature into Set_Temp for any given state

;The following variables are used for serial port communication
Count2ms:			ds 1
Result:				ds 2
upper_bound: 		ds 1
lower_bound: 		ds 1
computed_DC:		ds 1
Duty_Cycle: 		ds 1
Width_Count: 		ds 1
Count10ms:			ds 1
early_stop_time: 	ds 1
early_stop_temp: 	ds 1
Door_Open_Timer:	ds 1

Calibrated_Result:  ds 2


Error_Codes:		ds 1

;Variables for alarms (being replaced by registers in register bank 1)
;Count_one: ds 2 ; {R1, R0}
;Count_two: ds 2 ; {R3, R2}
;Count_three: ds 2 ; {R5, R4}

BSEG
mf: 			    		dbit 1
half_seconds_flag:  		dbit 1 	;Set to one in the ISR every time 500 ms had passed
;bits used throughout runtime
abort_flag: 				dbit 1	;used to flag aborting the runtime process
state1_exit_flag: 			dbit 1	;temperature activated flag, high when run-temp > Soak_Start_Temp_hex
state2_exit_flag: 			dbit 1	;time activated flag, high after state-run-time > Soak_Start_T_hex
state3_exit_flag: 			dbit 1	;temperature activated flag, high when run-temp > Reflow_Start_Temp_hex
state4_exit_flag: 			dbit 1	;time activated flag, high after state-run-time > Reflow_Start_T_hex
state5_exit_flag: 			dbit 1	;temperature activated flag, high when run-temp < 60
state_display_flag: 		dbit 1 	;determines what will be displayed for the state during runtime
state_display_flag2:		dbit 1	; a flag that is used to print the state display

Probe_Flag: dbit 1
Door_Open:					dbit 1


;The following bits are used for serial port communication
Tx_Ready:					dbit 1
Remote_Start:				dbit 1
Remote_Stop:				dbit 1
Remote_Data:				dbit 1
Remote_STemp:				dbit 1
Remote_Stime:				dbit 1
Remote_RTemp:				dbit 1
Remote_Rtime:				dbit 1	;a flag used to tell the program that the temp needs to be changed, as well as the duty cycle calculations
change_temperature_flag:	dbit 1
full_power_flag:			dbit 1
early_stop_flag:			dbit 1
PWM_flag:					dbit 1

One_Sec: 					dbit 1
One_Sec2:					dbit 1

state1tempflag:				dbit 1
state3tempflag:				dbit 1
Check_Code_1: 				dbit 1

;Flags for alarms
flag_one: dbit 1
flag_two: dbit 1
flag_three: dbit 1

  CSEG  
B0 		equ 	P2.6		;the signal that increments the cursor
B1 		equ 	P2.7		;the signal the selects the option the cursor is hovering
B2		equ 	P2.5		;the signal that decrements the cursor
B3		equ 	P2.4		;the signal that toggles settings when 
;below needs to be changed
ESTOP	equ 	P0.2

; These ’EQU’ must match the wiring between the microcontroller and ADC
CE_ADC  EQU P2.0	;SS'
MY_MOSI EQU P2.1	;MOSI
MY_MISO EQU P2.2	;MISO
MY_SCLK EQU P2.3 	;CLK
; These ’EQU’ must match the wiring between the microcontroller and LCD
LCD_RS 	equ 	P1.1
LCD_RW 	equ 	P1.2
LCD_E  	equ 	P1.3		;this is the pin that enables the menu LCD	(clr)
;LCD_SE equ		;this is the pin that enables the status LCD	(clr)
LCD_D4 	equ 	P3.2	
LCD_D5 	equ 	P3.3
LCD_D6 	equ 	P3.4

LCD_D7 	equ 	P3.5	
;used for serial communication
P_out 	equ 	P0.1
DoorPIN equ 	P0.7


CLEARLINE:  	db		'                ', 0	;used to clear the LCD

;Home display strings
HomeTop1: 	  	db 			'Start<  Settings', 0
HomeTop2: 		db 			'Start  >Settings', 0
HomeTop3: 		db 			'Start   Settings', 0
HomeBtm1: 		db 			'Preset <  Probes', 0
HomeBtm2: 		db 			'Preset   >Probes', 0
HomeBtm3: 		db 			'Preset    Probes', 0

;Preset select display strings
PresetTop1: 	  	db 		'Back<    Preset1', 0
PresetTop2: 		db 		'Back    >Preset1', 0
PresetTop3: 		db 		'Back     Preset1', 0
PresetBtm1: 		db 		'Preset2< Preset3', 0
PresetBtm2: 		db 		'Preset2 >Preset3', 0
PresetBtm3: 		db 		'Preset2  Preset3', 0

;Settings display strings
SettingsTop1: 	  	db 		'Save<      Other', 0
SettingsTop2: 		db 		'Save      >Other', 0
SettingsTop3: 		db 		'Save       Other', 0
SettingsBtm1: 		db 		'Soak-T< Reflow-T', 0
SettingsBtm2: 		db 		'Soak-T >Reflow-T', 0
SettingsBtm3: 		db 		'Soak-T  Reflow-T', 0


;Other Strings
SelectPreset: 		db 			'Select Preset',0
;SaveSettingsQ1: 	db 			'Save the settings?',0
SaveSettings: 		db 			'Choose preset #',0
SaveSettings1: 		db 			'to save to:',0
SettingsSaved: 		db 			'Settings Saved',0
SaveSettings?: 		db 			'Save Settings?',0
SoakSettings1: 		db 			'Temp    Duration', 0
ReflowSettings1: 	db 			'Temp    Duration', 0
leftpoint:			db 			'<',0
rightpoint: 		db 			'>',0
CLEARCHAR:			db			' ',0
CLEARHALFLINE:		db			'        ',0
o: 					db 			'O',0

;runtime strings
CurrentStateSetup:  db 			'xxxxxxxx', 0
CurrentTempSetup:   db 			'ccccc', 0
CurrentRTimeSetup:  db 			'rrrr', 0
CurrentTimeSetup:   db 			'tttt', 0

;state names
RampToSoak: 		db 			'RampToSoak', 0
Soak: 			    db 			'Soak', 0
RampToPeak: 		db 			'RampToPeak', 0
Reflow:			    db 			'Reflow', 0
Cooling:		    db 			'Cooling', 0
StateDiagramLayout: db 			'-----', 0
EXITTEXTTOP:		db			'User exception',0
EXITTEXTBTM:		db			'Aborting',0

;error codes
ERROR:				db 			'ERROR', 0

;delete these later
COOL:			db 'COOL',0
HEAT:			db 'heat',0

ProbeTop:		db 'Probe1    Probe3',0
ProbeBtm:		db 'Probe2    Result',0

;splashscreen


;------------------------------;
;Setup_System
;------------------------------;
Setup_System:
;	lcall Timer0_Init
	lcall Timer1_Init
    lcall Timer2_Init
    lcall InitSerialPort
    
    setb EA   ; Enable Global interrupts
	mov Current_Preset, 			#0x01
	
	;soak initializing
	mov	Soak_Settings_T_hex, 		#0x00
	mov	Soak_Settings_Temp_hex, 	#0x00
	mov	Soak_Preset1_T_hex, 		#115
	mov	Soak_Preset2_T_hex, 		#60
	mov	Soak_Preset3_T_hex, 		#120
	mov	Soak_Preset1_Temp_hex, 		#150
	mov	Soak_Preset2_Temp_hex, 		#150
	mov	Soak_Preset3_Temp_hex, 		#150
	;reflow initializing
	mov	Reflow_Settings_T_hex,		#0x00
	mov	Reflow_Preset1_T_hex, 		#75
	mov	Reflow_Preset2_T_hex, 		#45
	mov	Reflow_Preset3_T_hex, 		#75
	mov	Reflow_Settings_Temp_hex, 	#0x00
	mov	Reflow_Preset1_Temp_hex, 	#217
	mov	Reflow_Preset2_Temp_hex, 	#217
	mov	Reflow_Preset3_Temp_hex, 	#217
	;start of the process initializing, changes in program.
	mov	Soak_Start_T_hex, 			#0x00
	mov	Reflow_Start_T_hex, 		#0x00
	mov	Soak_Start_Temp_hex, 		#0x00
	mov	Reflow_Start_Temp_hex, 		#0x00
	;initializing oven info
	clr abort_flag
	mov state1_exit_flag, 			#0x00
	mov state2_exit_flag, 			#0x00
	mov state3_exit_flag, 			#0x00
	mov state4_exit_flag, 			#0x00
	mov oven_state, 				#0x00
	clr state_display_flag2
	clr state_display_flag
	;initializing the timers
	mov BCD_counter+0, 				#0x00
	mov BCD_counter+1,				#0x00
	mov BCD_state_counter+0,		#0x00
	mov BCD_state_counter+1,		#0x00
	mov P0M0, #0
	mov P0M1, #0
    ;Temp variables
    mov Temp, 						#0x00
    mov Calibrated_Result+0,		#0x00
    mov Calibrated_Result+1,		#0x00
    mov Room_Temp+1,				#high(ROOM_T)
    mov Room_Temp+0,				#low(ROOM_T)
    mov Set_Temp,					#0x00
    setb change_temperature_flag
   ; mov early_stop_bound, 			#150
    clr Remote_Start
    clr Remote_Stop
    clr Remote_Data
 	; Alarm variables
    setb SOUND_OUT
    clr flag_one
    clr flag_two
    clr flag_three
    
    ;mov Count_one, 				#0x00
    ;mov Count_two,					#0x00
    ;mov Count_three,				#0x00
    setb RS0
    clr a
    mov r0,							a
    mov r1, 						a
    mov r2,							a
    mov r3,							a
    mov r4,							a
    mov r5,							a
    clr RS0
 
	ret
	
Serial_ISR:
	jnb TI, Rx_ISR
	clr TI
	setb Tx_Ready
	reti
Rx_ISR:
    clr RI
    push acc
    push psw
    mov a, SBUF
    jb Remote_Data, Take_Data
    lcall take_instruction
Rx_Done:
    pop psw
    pop acc
    reti
Take_Data:

	;cpl P3.6	;debugging.
	
	clr Remote_Data
	jnb Remote_STemp, check_Stime
	mov Soak_Settings_Temp_hex, a
	mov Soak_Settings_Temp_hex+1, #0
	sjmp Save_Remote_Settings
check_Stime:
	jnb Remote_Stime, check_RTemp
	mov Soak_Settings_T_hex, a
	mov Soak_Settings_T_hex+1, #0
	sjmp Save_Remote_Settings
check_RTemp:
	jnb Remote_RTemp, check_Rtime
	mov Reflow_Settings_Temp_hex, a
	mov Reflow_Settings_Temp_hex+1, #0
	sjmp Save_Remote_Settings
check_Rtime:
	jnb Remote_Rtime, Rx_Error
	mov Reflow_Settings_T_hex, a
	mov Reflow_Settings_T_hex+1, #0
	sjmp Save_Remote_Settings
Rx_Error:
	sjmp Rx_Done
Save_Remote_Settings:
	Check_Current_Preset2(1,2,3)
	ljmp Rx_Done
	
;------------------------------;
;functions for serial communication
;------------------------------;

INIT_SPI:
	 setb MY_MISO ; Make MISO an input pin
	 clr MY_SCLK ; For mode (0,0) SCLK is zero
	 ret

DO_SPI_G:
	 push acc
	 mov R4, #0 ; Received byte stored in R1
	 mov R5, #8 ; Loop counter (8-bits)
DO_SPI_G_LOOP:
	 mov a, R3 ; Byte to write is in R0
	 rlc a ; Carry flag has bit to write
	 mov R3, a
	 mov MY_MOSI, c
	 setb MY_SCLK ; Transmit
	 mov c, MY_MISO ; Read received bit
	 mov a, R4 ; Save received bit in R1
	 rlc a
	 mov R4, a
	 clr MY_SCLK
	 djnz R5, DO_SPI_G_LOOP
	 pop acc
	 ret

; Send a character using the serial port
putchar:
    jnb Tx_Ready, putchar
    clr Tx_Ready
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
    ret
 
;------------------------------;
;Menu_Change_Cursor_Func
;------------------------------;
;The necessary function used to change the cursors position
Menu_Change_Cursor_Func:
	;first case to check is there are no other funcs enabled
	mov a, R2		
	cjne a, #00000000B, Menu_NOTONE_Func_E		;see if 1 function
	mov R1, #0x00							;reset cursor position
	ljmp Menu_Display_LCD
			
Menu_NOTONE_Func_E:
	;next check if there are 1 funcs enabled
	mov a, R2
	cjne a, #0x01, Menu_NOTTWO_FUNC_E		;see if 2 functions
	;now change the cursors position
	mov a, R1
	cjne a, #0xFF, Menu_Display_Not_Dec_Bound_TWOFUNC	; if not = to lower bout continue
	mov R1, #0x01
	ljmp Menu_Display_LCD
Menu_Display_Not_Dec_Bound_TWOFUNC:	
	cjne a, #0x02, Menu_Display_LCD	;if not = to uper bound, continue
	mov R1, #0x00							;was = to upper bound, reset
	ljmp Menu_Display_LCD
			
Menu_NOTTWO_FUNC_E:
	;next check if there are 1 funcs enabled
	mov a, R2
	cjne a, #0x02, Menu_NOTTHREE_FUNC_E	;see if 3 functions
	;now change the cursors position
	mov a, R1
	cjne a, #0xFF, Menu_Display_Not_Dec_Bound_THREEFUNC	; if not = to lower bout continue
	mov R1, #0x02
	ljmp Menu_Display_LCD
Menu_Display_Not_Dec_Bound_THREEFUNC:
	cjne a, #0x03, Menu_Display_LCD	;if not = to uper bound, continue
	mov R1, #0x00							;was = to upper bound, reset
	ljmp Menu_Display_LCD
			
Menu_NOTTHREE_FUNC_E:
	;next check if there are 1 funcs enabled
	mov a, R2
	cjne a, #0x03, Menu_NOTFOUR_FUNC_E	;see if 4 functions
	;now change the cursors position
	mov a, R1
	cjne a, #0xFF, Menu_Display_Not_Dec_Bound_FOURFUNC	; if not = to lower bout continue
	mov R1, #0x03
	ljmp Menu_Display_LCD
Menu_Display_Not_Dec_Bound_FOURFUNC:
	cjne a, #0x04, Menu_Display_LCD	;if not = to uper bound, continue
	mov R1, #0x00							;was = to upper bound, reset
	ljmp Menu_Display_LCD
			
Menu_NOTFOUR_FUNC_E:
	ljmp Menu_Display_LCD	
Menu_Display_LCD:
	ret
	
;----------------------;
;Extra_Functions_Home
;----------------------;
Extra_Functions_Home:
	;first check what the preset is, and print it on the screen
	push acc
	mov a, Current_Preset
	cjne a, #0x01, Current_Preset_Not_1
	;The current preset is 1, print 1
	set_Cursor(2,7)
	Display_Char(#'1')
	sjmp Done_Displaying_Current_Preset
Current_Preset_Not_1:	
	cjne a, #0x02, Current_Preset_Not_2
	;The current preset is 2, print 2
	set_Cursor(2,7)
	Display_Char(#'2')
	sjmp Done_Displaying_Current_Preset
Current_Preset_Not_2:
	cjne a, #0x03, Current_Preset_Not_3
	;The current preset is 3, print 3
	set_Cursor(2,7)
	Display_Char(#'3')
	sjmp Done_Displaying_Current_Preset
	
Current_Preset_Not_3:
Done_Displaying_Current_Preset:

	;check if the computer has inputted a signal
	;if Remote_Start is high, start the process,
	jnb Remote_Start, Skip_Remote_Start
	
	lcall Start_Process
	clr Remote_Start
Skip_Remote_Start:

	pop acc
	ret
	
;check for error code 1
Error_Code_1Check:
	lcall clear_xy
	mov x+0, Probe1_Temp+0
	mov x+1, Probe1_Temp+1
	Load_Y(5000)
	lcall x_gt_y
	jnb mf, No_Probe1_Error
	orl Error_Codes, #10000000b
No_Probe1_Error:
	mov x+0, Probe2_Temp+0
	mov x+1, Probe2_Temp+1
	lcall x_gt_y
	jnb mf, No_Probe2_Error
	orl Error_Codes, #10000000b
No_Probe2_Error:
	mov x+0, Probe3_Temp+0
	mov x+1, Probe3_Temp+1
	lcall x_gt_y
	jnb mf, No_Probe3_Error
	orl Error_Codes, #10000000b
No_Probe3_Error:
	ret

;--------------------------------------------;
;Select_Presets and the preset functions
;--------------------------------------------;
Select_Presets:
	Menu_Branch(B0,B1,Menu_Back,1,Preset_1,1,Preset_2,1,Preset_3,PresetTop1,PresetTop2,PresetTop3,PresetBtm1,PresetBtm2,PresetBtm3,CLEARLINE, Menu_Null,B2)
	ret
Preset_1:
	mov Current_Preset, #0x01
	mov R0, #0x01
	ret
Preset_2:
	mov Current_Preset, #0x02
	mov R0, #0x01
	ret
Preset_3:
	mov Current_Preset, #0x03
	mov R0, #0x01
	ret
	
;--------------------------------------------;
;Settings and the settings functions
;--------------------------------------------;
Settings:
	;when first entering this setting editor, the current preset's time and temp
	;is put into the editor
	push acc
	mov a, Current_Preset 	;determine the current preset
	cjne a, #0x01, Loading_Preset_T_Not_1
	Load_Settings_TandTemp(1)
	sjmp Done_Loading_Preset_T
Loading_Preset_T_Not_1:
	cjne a, #0x02, Loading_Preset_T_Not_2
	Load_Settings_TandTemp(2)
	sjmp Done_Loading_Preset_T
Loading_Preset_T_Not_2:
	cjne a, #0x03, Loading_Preset_T_Not_3
	Load_Settings_TandTemp(3)
	sjmp Done_Loading_Preset_T

Loading_Preset_T_Not_3:
Done_Loading_Preset_T:
	pop acc
	Menu_Branch(B0,B1,Menu_Back,1,Menu_Null,1,Soak_Settings,1,Reflow_Settings,SettingsTop1,SettingsTop2,SettingsTop3,SettingsBtm1,SettingsBtm2,SettingsBtm3,CLEARLINE, Menu_Null, B2)
	;after exiting the settings, the program prompts you to save the new settings in one of the presets
	lcall Save_Settings
	ret

;Soak_Settings
Soak_Settings:
	;display the current soaksettings and allow the user to change them.
	push AR0		;used as the current selection tool
	push acc
	Menu_Display_Screen(SoakSettings1,CLEARLINE)
	mov R0, #0x00
	set_Cursor(2,5)
	Send_Constant_String(#leftpoint)
Soak_Settings_Loop:
	;check to see if user is going to exit the program
	jb B1, NOT_Exit_Soak_Settings_Loop ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B1, NOT_Exit_Soak_Settings_Loop ; if the 'B0' button is not pressed skip
	jnb B1, $
	pop acc
	pop AR0
	ret	
NOT_Exit_Soak_Settings_Loop:

	;first the cursor settings.
	jb B3, Skip_INC_Cursor_Soak_Settingstp ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B3, Skip_INC_Cursor_Soak_Settingstp ; if the 'B0' button is not pressed skip
	jnb B3, $
	sjmp Soak_Jump
	
Skip_INC_Cursor_Soak_Settingstp:
	ljmp Skip_INC_Cursor_Soak_Settings
	
Soak_Jump:
	Inc R0
	mov a, R0
	cjne a, #0x02, Soak_Cursor_No_Reset
	mov R0, #0x00
	mov a, #0x00

Soak_Cursor_No_Reset:
	cjne a, #0x00, Soak_Cursor_Not_0
	set_Cursor(2,5)
	Send_Constant_String(#leftpoint)
	set_Cursor(2,12)
	Send_Constant_String(#CLEARCHAR)
	ljmp Skip_INC_Cursor_Soak_Settings
Soak_Cursor_Not_0:
	set_Cursor(2,12)
	Send_Constant_String(#rightpoint)
	set_Cursor(2,5)
	Send_Constant_String(#CLEARCHAR)
	
Skip_INC_Cursor_Soak_Settings:
	;check if the user increments one of the options
	jb B0, Skip_INC_Soak_Setting ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#10)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B0, Skip_INC_Soak_Setting ; if the 'B0' button is not pressed skip
	jnb B0, $
	jnb B2, $
	
	mov a, R0
	cjne a, #0x00, Soak_Setting_INC_Not_Temp
	INC Soak_Settings_Temp_hex
	ljmp Skip_INC_Soak_Setting
Soak_Setting_INC_Not_Temp:
	INC Soak_Settings_T_hex
	ljmp Skip_INC_Soak_Setting
Skip_INC_Soak_Setting:

	;check if the user decrements one of the options
	jb B2, Skip_DEC_Soak_Setting ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#10)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B2, Skip_DEC_Soak_Setting ; if the 'B0' button is not pressed skip
	jnb B2, $
	jnb B0, $

	mov a, R0
	cjne a, #0x00, Soak_Setting_DEC_Not_Temp
	DEC Soak_Settings_Temp_hex
	ljmp Skip_DEC_Soak_Setting
Soak_Setting_DEC_Not_Temp:
	DEC Soak_Settings_T_hex
	ljmp Skip_DEC_Soak_Setting
Skip_DEC_Soak_Setting:
	
;now display the values onto the screen by converting them to BCD's
	Hex_to_BCD_Print(Soak_Settings_Temp_hex,2,1)
	Hex_to_BCD_Print(Soak_Settings_T_hex,2,13)

	;finished displaying the correct values, continue.
ljmp Soak_Settings_Loop

;Reflow_Settings	
Reflow_Settings:
		;display the current soaksettings and allow the user to change them.
	push AR0		;used as the current selection tool
	push acc
	Menu_Display_Screen(ReflowSettings1,CLEARLINE)
	mov R0, #0x00
	set_Cursor(2,5)
	Send_Constant_String(#leftpoint)
Reflow_Settings_Loop:
	;check to see if user is going to exit the program
	jb B1, NOT_Exit_Reflow_Settings_Loop ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B1, NOT_Exit_Reflow_Settings_Loop ; if the 'B0' button is not pressed skip
	jnb B1, $
	pop acc
	pop AR0
	ret	
NOT_Exit_Reflow_Settings_Loop:

	;first the cursor settings.
	jb B3, Skip_INC_Cursor_Reflow_Settingstp ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B3, Skip_INC_Cursor_Reflow_Settingstp ; if the 'B0' button is not pressed skip
	jnb B3, $
	sjmp Reflow_Jump
	
Skip_INC_Cursor_Reflow_Settingstp:
	ljmp Skip_INC_Cursor_Reflow_Settings
	
Reflow_Jump:
	Inc R0
	mov a, R0
	cjne a, #0x02, Reflow_Cursor_No_Reset
	mov R0, #0x00
	mov a, #0x00

Reflow_Cursor_No_Reset:
	cjne a, #0x00, Reflow_Cursor_Not_0
	set_Cursor(2,5)
	Send_Constant_String(#leftpoint)
	set_Cursor(2,12)
	Send_Constant_String(#CLEARCHAR)
	ljmp Skip_INC_Cursor_Reflow_Settings
Reflow_Cursor_Not_0:
	set_Cursor(2,12)
	Send_Constant_String(#rightpoint)
	set_Cursor(2,5)
	Send_Constant_String(#CLEARCHAR)
	
Skip_INC_Cursor_Reflow_Settings:
	;check if the user increments one of the options
	jb B0, Skip_INC_Reflow_Setting ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#10)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B0, Skip_INC_Reflow_Setting ; if the 'B0' button is not pressed skip
	jnb B0, $
	jnb B2, $

	mov a, R0
	cjne a, #0x00, Reflow_Setting_INC_Not_Temp
	INC Reflow_Settings_Temp_hex
	ljmp Skip_INC_Reflow_Setting
Reflow_Setting_INC_Not_Temp:
	INC Reflow_Settings_T_hex
	ljmp Skip_INC_Reflow_Setting
Skip_INC_Reflow_Setting:

	;check if the user decrements one of the options
	jb B2, Skip_DEC_Reflow_Setting ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#10)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B2, Skip_DEC_Reflow_Setting ; if the 'B0' button is not pressed skip
	jnb B2, $
	jnb B0, $

	mov a, R0
	cjne a, #0x00, Reflow_Setting_DEC_Not_Temp
	DEC Reflow_Settings_Temp_hex
	ljmp Skip_DEC_Reflow_Setting
Reflow_Setting_DEC_Not_Temp:
	DEC Reflow_Settings_T_hex
	ljmp Skip_DEC_Reflow_Setting
Skip_DEC_Reflow_Setting:
	
;now display the values onto the screen by converting them to BCD's
	Hex_to_BCD_Print(Reflow_Settings_Temp_hex,2,1)
	Hex_to_BCD_Print(Reflow_Settings_T_hex,2,13)
	
	;finished displaying the correct values, continue.
ljmp Reflow_Settings_Loop

Save_Settings:
	;prompt the user to save the current settings into one of the presets
	push AR0
	mov R0, Current_Preset
	Push AR0
	push acc	
	Menu_Display_Screen(SaveSettings,SaveSettings1)

Save_Settings_Loop:
	jb B1, Save_Settings_Looptp ; if the 'B1' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B1, Save_Settings_Looptp ; if the 'B1' button is not pressed skip
	;if the button is pressed, exit the loop after saving the correct information into the appropriate slots
	jnb B1, $
	
	;now check what preset to save to, and save the proper information to the global variables
	mov a, Current_Preset
	cjne a, #0x01, Save_Not_1
	Save_Settings_TandTemp(1)
	ljmp Save_Not_3
	
Save_Not_1:
	cjne a, #0x02, Save_Not_2
	Save_Settings_TandTemp(2)
	ljmp Save_Not_2
Save_Not_2:
	cjne a, #0x03, Save_Not_3
	Save_Settings_TandTemp(3)
	ljmp Save_Not_3
Save_Not_3:
	;exit the save and return to the main menu
	pop acc
	pop AR0
	mov Current_Preset, R0
	Pop AR0
	ret			
	
Save_Settings_Looptp:
	mov a, Current_Preset
	cjne a, #0x01, Save_Draw_Not_1
	set_Cursor(2,13)
	Display_Char(#'1')
	ljmp Save_Draw_Not_3
Save_Draw_Not_1:
	cjne a, #0x02, Save_Draw_Not_2
	set_Cursor(2,13)
	Display_Char(#'2')
	ljmp Save_Draw_Not_3
Save_Draw_Not_2:
	cjne a, #0x03, Save_Draw_Not_3
	set_Cursor(2,13)
	Display_Char(#'3')
	ljmp Save_Draw_Not_3
Save_Draw_Not_3:

	;now check for incrementing the position
	jb B0, Skip_INC_Settings_Preset ; if the 'B1' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B0, Skip_INC_Settings_Preset ; if the 'B1' button is not pressed skip
	jnb B0, $
	;increment the settings preset,
	INC a
	mov Current_Preset, a
	cjne a, #0x04, No_Reset_Preset_NUM		;check if max
	mov	Current_Preset, #0x01
No_Reset_Preset_NUM:
	
Skip_INC_Settings_Preset:
	ljmp Save_Settings_Loop
	
;-----------------------------------------------------------------------;;-----------------------------------------------------------------------;;-----------------------------------------------------------------------;
;this Code needs to be added as the main page of the system
;-----------------------------------------------------------------------;;-----------------------------------------------------------------------;;-----------------------------------------------------------------------;
mainprogram:
	;setting up the program
	mov SP, #0x7F
    lcall LCD_4BIT
    lcall Setup_System
    lcall Display_System_Credits
    ;the home page of the system
	Menu_Branch(B0,B1,Start_Process,1,Settings,1,Select_Presets,1,Menu_Probes,HomeTop1,HomeTop2,HomeTop3,HomeBtm1,HomeBtm2,HomeBtm3,CLEARLINE, Extra_Functions_Home,B2)
	
	
Menu_Probes:
	Menu_Display_Screen(ProbeTop,ProbeBtm)
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
Menu_Probes_Loop:
		;check if the emergency button has been pressed
	jb B1, Skip_Exit_Probes ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb B1,Skip_Exit_Probes ; if the 'B0' button is not pressed skip
	jnb B1, $
	;check if the user wants to exit
	ret
Skip_Exit_Probes:	
	lcall Error_Code_1Check	
	mov x + 0, Probe1_Temp+0
	mov x + 1, Probe1_Temp+1
	mov x + 2, #0x00
	mov x + 3, #0x00
	lcall hex2bcd		;change hex number to bcd so it can be displayed
	set_Cursor(1,1)
	Display_BCD(bcd+2)
	Display_BCD(bcd+1)
	Display_Char(#'.')
	Display_BCD(bcd+0)
	
	mov x + 0, Probe2_Temp+0
	mov x + 1, Probe2_Temp+1
	mov x + 2, #0x00
	mov x + 3, #0x00
	lcall hex2bcd		;change hex number to bcd so it can be displayed
	set_Cursor(2,1)
	Display_BCD(bcd+2)
	Display_BCD(bcd+1)
	Display_Char(#'.')
	Display_BCD(bcd+0)
	
	mov x + 0, Probe3_Temp+0
	mov x + 1, Probe3_Temp+1
	mov x + 2, #0x00
	mov x + 3, #0x00
	lcall hex2bcd		;change hex number to bcd so it can be displayed
	set_Cursor(1,10)
	Display_BCD(bcd+2)
	Display_BCD(bcd+1)
	Display_Char(#'.')
	Display_BCD(bcd+0)
	
	mov x + 0, Calibrated_Result+0
	mov x + 1, Calibrated_Result+1
	mov x + 2, #0x00
	mov x + 3, #0x00
	lcall hex2bcd		;change hex number to bcd so it can be displayed
	set_Cursor(2,10)
	Display_BCD(bcd+2)
	Display_BCD(bcd+1)
	Display_Char(#'.')
	Display_BCD(bcd+0)

	ljmp Menu_Probes_Loop
	
	
;----------------------;
;Start_Process
;----------------------;
;when the user starts the process, this is entered.
Start_Process:
	push acc
	;first move the preset variables into the process variabes
	mov a, Current_Preset 	;determine the current preset
	cjne a, #0x01, Loading_Preset_Start_T_Not_1
	Load_Start_TandTemp(1)
	sjmp Done_Loading_Preset_Start_T
	
Loading_Preset_Start_T_Not_1:
	cjne a, #0x02, Loading_Preset_Start_T_Not_2
	Load_Start_TandTemp(2)
	sjmp Done_Loading_Preset_Start_T
	
Loading_Preset_Start_T_Not_2:
	cjne a, #0x03, Loading_Preset_Start_T_Not_3
	Load_Start_TandTemp(3)
	sjmp Done_Loading_Preset_Start_T
	
Loading_Preset_Start_T_Not_3:

	;now the correct values have been stored in the process variables
Done_Loading_Preset_Start_T:
	set_Cursor(1,1)
	Send_Constant_String(#CLEARLINE)
	set_Cursor(2,1)
	Send_Constant_String(#CLEARLINE)
	;reset runtime timer to 0
	mov BCD_counter+0, 					#0x00
	mov BCD_counter+1,					#0x00
	mov BCD_state_counter+0,			#0x00
	mov BCD_state_counter+1,			#0x00
	mov oven_state, #0x01
	lcall Print_FSM_State_Info
	setb state1tempflag
	setb state3tempflag
	clr abort_flag
	setb Check_Code_1
	lcall Oven_FSM
	mov R1, #0x00
	Menu_Display_LCD_Cursor(HomeTop1,HomeTop2,HomeTop3,HomeBtm1,HomeBtm2,HomeBtm3,CLEARLINE)
	pop acc
	ret

;------------------------------;
;Print_FSM_State_Info
;------------------------------;
Print_FSM_State_Info:
	;print the name of the current state you are in.
	jb state_display_flag, Display_Diagramtp
	ljmp Print_FSM_Jump
Display_Diagramtp:			;used to get around jump limits
	ljmp Display_Diagram
		
Print_FSM_Jump:
	mov a, oven_state
	cjne a, #0x01, Print_FSM_Check_S2
	lcall Print_FSM_Clear_Name
	Print_FSM_Info(RampToSoak,7)
	ljmp Print_FSM_Complete
	
Print_FSM_Check_S2:
	cjne a, #0x02, Print_FSM_Check_S3
	lcall Print_FSM_Clear_Name
	Print_FSM_Info(Soak,13)
	ljmp Print_FSM_Complete
	
Print_FSM_Check_S3:
	cjne a, #0x03, Print_FSM_Check_S4
	lcall Print_FSM_Clear_Name
	Print_FSM_Info(RampToPeak,7)
	ljmp Print_FSM_Complete
	
Print_FSM_Check_S4:
	cjne a, #0x04, Print_FSM_Check_S5
	lcall Print_FSM_Clear_Name
	Print_FSM_Info(Reflow,11)
	ljmp Print_FSM_Complete
	
Print_FSM_Check_S5:
	lcall Print_FSM_Clear_Name
	Print_FSM_Info(Cooling,10)
	ljmp Print_FSM_Complete

;If not displaying the name, display the position of the state
Display_Diagram:
	lcall Print_FSM_Clear_Name
	set_Cursor(1,12)
	Send_Constant_String(#StateDiagramLayout)
	;now check which state and print the corresponding position
	mov x + 0, Set_Temp
	mov x + 1, #0x00
	mov x + 2, #0x00
	mov x + 3, #0x00
	lcall hex2bcd
	set_Cursor(1,7)
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	;the above prints the desired temp beside the current temp
	mov a, oven_state
	cjne a, #0x01, Print_FSM_Diagram_Check_S2
	Print_FSM_Info(o,12)
	ljmp Print_FSM_Complete
	
Print_FSM_Diagram_Check_S2:
	cjne a, #0x02, Print_FSM_Diagram_Check_S3
	Print_FSM_Info(o,13)
	ljmp Print_FSM_Complete
	
Print_FSM_Diagram_Check_S3:
	cjne a, #0x03, Print_FSM_Diagram_Check_S4
	Print_FSM_Info(o,14)
	ljmp Print_FSM_Complete
	
Print_FSM_Diagram_Check_S4:
	cjne a, #0x04, Print_FSM_Diagram_Check_S5
	Print_FSM_Info(o,15)
	ljmp Print_FSM_Complete
	
Print_FSM_Diagram_Check_S5:

	Print_FSM_Info(o,16)
	ljmp Print_FSM_Complete
Print_FSM_Complete:
	ret
;------------------------------;
;Print_FSM_Time_Info
;------------------------------; 
Print_FSM_Time_Info:
	set_Cursor(2,1)
	Display_BCD(BCD_counter+1)
	Display_BCD(BCD_counter+0)
	set_Cursor(2,13)
	Display_BCD(BCD_state_counter+1)
	Display_BCD(BCD_state_counter+0)
	ret
;------------------------------;
;Print_FSM_Temp_Info
;------------------------------; 
Print_FSM_Temp_Info:
	
	mov x + 0, Temp+0
	mov x + 1, Temp+1
	mov x + 2, #0x00
	mov x + 3, #0x00
	
	lcall hex2bcd		;change hex number to bcd so it can be displayed
	set_Cursor(1,1)
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)

	ret
	
;------------------------------;
;Check_Runtime_Errors
;------------------------------;
Check_Runtime_Errors:
	
	lcall Error_Code_1
	lcall Error_Code_2
	ret	

Error_Code_1:				;at runtime = 50, if temp < 50 abort
	mov a, BCD_counter+1
	mov b, #10
	mul ab
	mov R7, a
	mov a, BCD_counter+0
	swap a
	anl a, #0x0f
	add a, R7
	mov b, #10
	mul ab
	mov R7, a
	mov a, BCD_counter+0
	anl a, #0x0f
	add a, R7
	subb a, #50
	jnz skip_code_1
	mov a, Temp
	subb a, #60
	jnc skip_code_1
	setb abort_flag
	orl Error_Codes, #01000000b	
skip_code_1:
	ret

;	mov bcd+0, bcd_counter+0
;	mov bcd+1, bcd_counter+1
;	mov bcd+2, #0
;	mov bcd+3, #0
;	mov bcd+4, #0
;	lcall bcd2hex
;	mov a, x+0
;	cjne a, #50, Checking_Overflow_Time
;C;hecking_Overflow_Time:
;	jc Less_Than_50s
;	mov a, Temp
;	cjne a, #60, Checking_Temp_Overflow
;	ljmp Less_Than_50s
;C;hecking_Temp_Overflow:
;	jc ERROR_1
;	ljmp Less_Than_50s
;ERROR_1:
;	cpl p3.6
;	setb abort_flag	
;	orl Error_Codes, #01000000b	
;L;ess_Than_50s:
;	ret
	
Error_Code_2:				;if door not closed during runtime, abort()())()()()()()(()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()
;	jnb	DoorPIN, Error_2_clear
;	setb abort_flag
;Error_2_clear:
	ret
	
;------------------------------;
;Oven_Abort_State
;------------------------------;
Oven_Abort_State:
	set_Cursor(1,1)
	Send_Constant_String(#CLEARLINE)
	set_Cursor(1,1)
	Send_Constant_String(#EXITTEXTTOP)
	set_Cursor(2,1)
	Send_Constant_String(#CLEARLINE)
	set_Cursor(2,1)
	Send_Constant_String(#EXITTEXTBTM)
	mov Set_Temp, #0x0A
	setb change_temperature_flag
	mov oven_state, #0x00
	lcall Reset_Alarms
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
	ret
;------------------------------;
;Oven_FSM
;------------------------------;
Oven_FSM:
	
	lcall Check_Runtime_Errors
	jb abort_flag, Oven_Abort_Statetp
	ljmp Oven_Abort_Statetp2
Oven_Abort_Statetp:
	ljmp Oven_Abort_State
Oven_Abort_Statetp2:			;above gets around maximum offset

	lcall Print_FSM_Time_Info
	lcall Print_FSM_Temp_Info
	
	;display the screen if required
	jnb state_display_flag2, Oven_FSM_Skip_Display
	lcall Print_FSM_State_Info
	clr state_display_flag2			;reset flag

	;check for remote stop
	jnb Remote_Stop, Skip_Remote_Stop
	clr Remote_Stop
	ljmp Oven_Abort_State
Skip_Remote_Stop:
	
Oven_FSM_Skip_Display:
	mov a, oven_state
	;check if the emergency button has been pressed
	jb ESTOP, Oven_State1 ; if the 'B0' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb ESTOP,Oven_State1 ; if the 'B0' button is not pressed skip
	jnb ESTOP, $
	;ESTOP pressed, jump to abort state
	ljmp Oven_Abort_State

;------;
;state1;
Oven_State1:

State1_Temp_Flag_Change_Jump:
	cjne a, #0x01, Oven_State2

	jnb state1tempflag, State1_hop
	FSM_Set_Desired_Temp(Soak_Start_Temp_hex)
	setb change_temperature_flag
	clr state1tempflag
State1_hop:
	
	;compare the desired tempurature of the state and check if we move to next state.
	mov a, Temp
	cjne a, Soak_Start_Temp_hex, FSM_Check_Carry_Soak
	;if equal change to state 2
	sjmp State_1To2_Transition
FSM_Check_Carry_Soak:
	jnc State_1To2_Transition 	;if carry not set, change state
	ljmp Oven_FSM
State_1To2_Transition:	
	
	clr state1_exit_flag
	INC oven_state
	mov BCD_state_counter, #0x00
	mov BCD_state_counter+1, #0x00
	lcall Print_FSM_State_Info
	
	lcall Trigger_Short_Alarm
	
	ljmp Oven_FSM

;------;
;state2;	
Oven_State2:
	cjne a, #0x02, Oven_State3
	
	;determine if the desired state time has finished
	mov a, BCD_state_counter+1
	mov b, #10
	mul ab
	mov R7, a
	mov a, BCD_state_counter+0
	swap a
	anl a, #0x0f
	add a, R7
	mov b, #10
	mul ab
	mov R7, a
	mov a, BCD_state_counter+0
	anl a, #0x0f
	add a, R7
	cjne a, Soak_Start_T_hex, Oven_FSMtp2

	clr state2_exit_flag
	mov oven_state, #0x03
	mov BCD_state_counter+0, #0x00
	mov BCD_state_counter+1, #0x00
	lcall Print_FSM_State_Info
	
	lcall Trigger_Short_Alarm
	
Oven_FSMtp2:	
	ljmp Oven_FSM
;------;
;state3;	
Oven_State3:
	cjne a, #0x03, Oven_State4
	
	jnb state3tempflag, State3_hop	
	FSM_Set_Desired_Temp(Reflow_Start_Temp_hex)
	setb change_temperature_flag
	clr state3tempflag
State3_hop:
	
	
State3_Temp_Flag_Change_Jump:

	;compare the desired tempurature of the state and check if we move to next state.
	mov a, Temp
	cjne a, Reflow_Start_Temp_hex, FSM_Check_Carry_Reflow
	;if equal change to state 2
	sjmp State_3To4_Transition
FSM_Check_Carry_Reflow:
	jnc State_3To4_Transition 	;if carry not set, change state
	ljmp Oven_FSM
State_3To4_Transition:	
	
	clr state3_exit_flag
	mov oven_state, #0x04
	mov BCD_state_counter, #0x00
	mov BCD_state_counter+1, #0x00
	lcall Print_FSM_State_Info
	
	lcall Trigger_Short_Alarm
	
	ljmp Oven_FSM

Oven_FSMtp3:
	ljmp Oven_FSM
;------;
;state4;
Oven_State4:

	cjne a, #0x04, Oven_State5

	;determine if the desired state time has finished
	mov a, BCD_state_counter+1
	mov b, #10
	mul ab
	mov R7, a
	mov a, BCD_state_counter+0
	swap a
	anl a, #0x0f
	add a, R7
	mov b, #10
	mul ab
	mov R7, a
	mov a, BCD_state_counter+0
	anl a, #0x0f
	add a, R7
	cjne a, Reflow_Start_T_hex, Oven_FSMtp

	clr state4_exit_flag
	mov oven_state, #0x05
	mov BCD_state_counter, #0x00
	mov BCD_state_counter+1, #0x00
	lcall Print_FSM_State_Info
	
	lcall Trigger_Long_Alarm
	ljmp Oven_FSM
;------;
;state5;
Oven_State5:
	mov Set_Temp, #0x0A	;set the desired temp to 0
	setb change_temperature_flag
	
	;compare the desired tempurature of the state and check if we move to next state.
	mov a, Temp
	cjne a, #60, FSM_Check_Carry_Cool
	;if equal change to state 2
	sjmp State_5To0_Transition
FSM_Check_Carry_Cool:
	jc State_5To0_Transition 	;if carry not set, change state
	ljmp Oven_FSM
State_5To0_Transition:	
	lcall Trigger_Beeping_Alarm
	mov oven_state, #0
	ret
	
Oven_FSMtp:
	ljmp Oven_FSM
	
end 