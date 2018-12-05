cseg


;------------------------------------------------------------------------------;
;This Macro was made by Lewis Mason, January 2018		
;LCD_Menu_Branch creates another branch segment of a in depth
;menu.
;NOTE: THIS FUNCTION REQUIRES THE USE OF FUNCTIONS FROM LCD4_bit
;
;Requirements:
;		2 pushbuttons
;		Either 3 function-name parameters, or less than 3 and the
;			the remainder named "NULL_FUNCTION"
;
;Menu_Branch(			cursorINC,   cursorselect, Func1,    FUNC2ENABLE,      Func2,  FUNC3ENABLE,    Func3,   FUNC4ENABLE,    Func4,    UP<,UP>,UP_,DN<,DN>,DN_,Blankstr, ConstFunc, CursorDec)				
;				NAME   		NAME	   NAME    	1/0		NAME     1/0	  	NAME   	1/0		 NAME	----all string names------------	NAME	NAME  
;				%0		 %1	    %2		 %3		 %4       %5		 %6 	 %7 	          %8	  %9  %10 %11 %12 %13 %14 %15		%16	%17
;
;------------------------------------------------------------------------------;

Menu_Branch mac
	push ar0
	push ar1
	push ar2
	push ar3
	push ar4
	push ar5
	push ar6
	push ar7
	push acc
	mov R0, #0x00			;R0 is the exit flag, reset the exit flag
	mov R1, #0x00			;R1 is the Cursor position register
	mov R2, #0x00			;R2 is the number of functions flag
	
	
	;We put the information about the functions in R2,bits 0,1,2 correspond to funcs 2,3,4
	Menu_Setup_Function_Register(%3,%5,%7)	;sets up the function flag register
	;R2 is the function flag register
	
	Menu_Display_LCD_Cursor(%9,%10,%11,%12,%13,%14,%15)	;display on LCD

;The loop that will happen over and over in each level of the menu
Menu_Loop%M:

	;First, Check to see if the user wants to INC the cursors location
	jb %0, Menu_Skip_Cursor_INCtp%M 	; if the '%0' button is not pressed skip
	Wait_Milli_Seconds(#10)			; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb %0, Menu_Skip_Cursor_INCtp%M 	; if the '%0' button is not pressed skip
	jnb %0, $				; Wait for button release.
	jnb %17, $				; Wait for button release.
	;The below code is used to get around the max jb jump distance
	sjmp Menu_INC_Cursor%M
Menu_Skip_Cursor_INCtp%M:
	ljmp Menu_Skip_Cursor_INC%M
Menu_INC_Cursor%M:	
	INC R1							;increment the cursors position
	lcall Menu_Change_Cursor_Func				;verify cursors position.
	Menu_Display_LCD_Cursor(%9,%10,%11,%12,%13,%14,%15)	;display on LCD
	
Menu_Skip_Cursor_INC%M:

	;Then, Check to see if the user wants to DEC the cursors location
	jb %17, Menu_Skip_Cursor_DECtp%M 	; if the '%0' button is not pressed skip
	Wait_Milli_Seconds(#10)			; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb %17, Menu_Skip_Cursor_DECtp%M 	; if the '%0' button is not pressed skip
	jnb %17, $				; Wait for button release.
	jnb %0, $				; Wait for button release.
	;The below code is used to get around the max jb jump distance
	sjmp Menu_DEC_Cursor%M
Menu_Skip_Cursor_DECtp%M:
	ljmp Menu_Skip_Cursor_DEC%M
Menu_DEC_Cursor%M:	
	DEC R1							;increment the cursors position
	lcall Menu_Change_Cursor_Func				;verify cursors position.
	Menu_Display_LCD_Cursor(%9,%10,%11,%12,%13,%14,%15)	;display on LCD
	
Menu_Skip_Cursor_DEC%M:

	;Check if the user wanted to exit the level of the menu
	mov a, R0
	cjne a, #0x01, Menu_Stay%M 	;if the flag is not 1, continue program, otherwise reset flag and return
	mov R0, #0x00
	ljmp Menu_Exit_Level%M
	
Menu_Stay%M:	
	;now the code that operates when the "select" button is pressed
	jb %1, Menu_Skip_Select_Changetp%M 	; if the '%1' button is not pressed skip
	Wait_Milli_Seconds(#50)			; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb %1, Menu_Skip_Select_Changetp%M 	; if the '%1' button is not pressed skip
	jnb %1, $				; Wait for button release
	;The below code is used to get around the max jb jump distance 
	sjmp Menu_Select_Change%M
Menu_Skip_Select_Changetp%M:
	ljmp Menu_Skip_Select_Change%M	;the button was not pressed.
	
Menu_Select_Change%M:
	Menu_Select_Functions(%2,%4,%6,%8)

	;after selecting the function and exiting it, reset the cursor position and the screen
	mov R1, #0x00
	Menu_Display_LCD_Cursor(%9,%10,%11,%12,%13,%14,%15)

Menu_Skip_Select_Change%M:
	
	;calling the operation function, which does stuff every cycle.
	lcall %16
	ljmp Menu_Loop%M

Menu_Exit_Level%M:
	pop acc
	pop  ar7
	pop  ar6
	pop  ar5
	pop  ar4
	pop  ar3
	pop  ar2
	pop  ar1
	pop  ar0
endmac	

;------------------------------;
;Menu_Select_Functions
;------------------------------;
Menu_Select_Functions mac
	
;We simply compare what number is in the cursor and enter that function
	mov a, R1
	cjne a, #0x00, Menu_Not_Func_One_Select%M
	;if here, then the cursor is on the above position
	lcall %0
	ljmp Menu_Done_Func%M
			
Menu_Not_Func_One_Select%M:
		mov a, R1
	cjne a, #0x01, Menu_Not_Func_Two_Select%M
	;if here, then the cursor is on the above position
	lcall %1
	ljmp Menu_Done_Func%M
			
Menu_Not_Func_Two_Select%M:
	mov a, R1
	cjne a, #0x02, Menu_Not_Func_Three_Select%M
	;if here, then the cursor is on the above position
	lcall %2
	ljmp Menu_Done_Func%M
			
Menu_Not_Func_Three_Select%M:
	mov a, R1
	cjne a, #0x03, Menu_Not_Func_Four_Select%M
	;if here, then the cursor is on the above position
	lcall %3
	ljmp Menu_Done_Func%M
			
Menu_Not_Func_Four_Select%M:

Menu_Done_Func%M:
	endmac

;------------------------------;
;Menu_Setup_Function_Register
;------------------------------;
Menu_Setup_Function_Register mac
	mov a, #0x00			;clear a
	;jnb %0, Menu_No_Func_2
	mov a, #0x0%0
	cjne a, #0x01, Menu_No_Func_2%M
	inc R2
	;orl a, #00000001B		;put a 1 in bit 0 to indicate FUNC 2 activated
Menu_No_Func_2%M:
	;jnb %1, Menu_No_Func_3
	mov a, #0x0%1
	cjne a, #0x01, Menu_No_Func_3%M
	inc R2
	;orl a, #00000010B		;put a 1 in bit 1 to indicate FUNC 3 activated
Menu_No_Func_3%M:
	;jnb %2, Menu_No_Func_4
	mov a, #0x0%2
	cjne a, #0x01, Menu_No_Func_4%M
	inc R2
	;orl a, #00000100B		;put a 1 in bit 2 to indicate FUNC 4 activated
Menu_No_Func_4%M:
				;put the result into R2, this indicates the #of funcs
	endmac
	
;------------------------------;
;Menu_Display_LCD_Cursor
;------------------------------;
Menu_Display_LCD_Cursor mac
	;display the screen after it has switched. This stays inside the 
	;change cursor part so it only updates when pressed, not constantly.
	mov a, R1
	cjne a, #0x00, Menu_Display_not_ONE%M
	Menu_Display_Cursor(%0,%5,%6)			
	ljmp Menu_Done_Display_Cursor_Change%M	
		
Menu_Display_not_ONE%M:
		mov a, R1
		cjne a, #0x01, Menu_Display_not_TWO%M
		Menu_Display_Cursor(%1,%5,%6)
		ljmp Menu_Done_Display_Cursor_Change%M
				
Menu_Display_not_TWO%M:
		mov a, R1
		cjne a, #0x02, Menu_Display_not_THREE%M
		Menu_Display_Cursor(%2,%3,%6)
		ljmp Menu_Done_Display_Cursor_Change%M
				
Menu_Display_not_THREE%M:
		mov a, R1
		cjne a, #0x03, Menu_Display_not_FOUR%M
		Menu_Display_Cursor(%2,%4,%6)	
		ljmp Menu_Done_Display_Cursor_Change%M
				
Menu_Display_not_FOUR%M:
Menu_Done_Display_Cursor_Change%M:
	endmac
	
	
;------------------------------;
;Save_Settings_T
;------------------------------;
;saves the settings of the input
Save_Settings_TandTemp mac
	push acc

	mov a, Soak_Settings_T_hex
	mov Soak_Preset%0_T_hex, a
	mov a, Reflow_Settings_T_hex
	mov Reflow_Preset%0_T_hex, a
	
	mov a, Soak_Settings_Temp_hex
	mov Soak_Preset%0_Temp_hex, a
	mov a, Reflow_Settings_Temp_hex
	mov Reflow_Preset%0_Temp_hex, a

	pop acc
	endmac


;------------------------------;
;Load_Settings_TandTemp
;------------------------------;
;saves the settings of the input
Load_Settings_TandTemp mac
	push acc

	mov a, Soak_Preset%0_T_hex
	mov Soak_Settings_T_hex, a	
	mov a, Reflow_Preset%0_T_hex
	mov Reflow_Settings_T_hex, a	
	
	mov a, Soak_Preset%0_Temp_hex
	mov Soak_Settings_Temp_hex, a	
	mov a, Reflow_Preset%0_Temp_hex
	mov Reflow_Settings_Temp_hex, a	

	pop acc
	endmac

;------------------------------;
;Load_Start_TandTemp
;------------------------------;
;saves the settings of the input
Load_Start_TandTemp mac
	push acc

	mov a, Soak_Preset%0_T_hex
	mov Soak_Start_T_hex, a	
	mov a, Reflow_Preset%0_T_hex
	mov Reflow_Start_T_hex, a	
	
	mov a, Soak_Preset%0_Temp_hex
	mov Soak_Start_Temp_hex, a	
	mov a, Reflow_Preset%0_Temp_hex
	mov Reflow_Start_Temp_hex, a	

	pop acc
	endmac	

;------------------------------;
;Menu_Display_Cursor
;------------------------------;
Menu_Display_Cursor mac
	set_Cursor(1,1)
	Send_Constant_String(#%2)
	set_Cursor(1,1)
	Send_Constant_String(#%0)		;display top half, cursor >
	;check if its required to display bottom half
	mov a, R2
	anl a, #0x02
	cjne a, #0x02, Skip_Displaying_Bottom%M
	set_Cursor(2,1)
	Send_Constant_String(#%2)
	set_Cursor(2,1)
	Send_Constant_String(#%1)		;display bottom half no cursor
Skip_Displaying_Bottom%M:
	endmac
	
;------------------------------;
;Menu_Display_Screen
;------------------------------;
Menu_Display_Screen mac
	set_Cursor(1,1)
	Send_Constant_String(#CLEARLINE)
	set_Cursor(2,1)
	Send_Constant_String(#CLEARLINE)
	set_Cursor(1,1)
	Send_Constant_String(#%0)
	set_Cursor(2,1)
	Send_Constant_String(#%1)
	endmac

;------------------------------;
;Check_Current_Preset
;------------------------------;
;checks the current preset and calls functions depending on the values
Check_Current_Preset mac	
	push acc
	
	mov a, Current_Preset
	cjne a, #0x01, Preset_Not_1%M
	lcall %0
	ljmp Preset_Not_3%M
	
Preset_Not_1%M:
	cjne a, #0x02, Preset_Not_2%M
	lcall %1
	ljmp Preset_Not_3%M
	
Preset_Not_2%M:
	cjne a, #0x03, Preset_Not_3%M
	lcall %2
	ljmp Preset_Not_3%M
	
Preset_Not_3%M:
	pop acc
	endmac
	
	
;------------------------------;
;Check_Current_Preset2
;------------------------------;
;checks the current preset and calls functions depending on the values
Check_Current_Preset2 mac	
	push acc
	
	mov a, Current_Preset
	cjne a, #0x01, Preset_Not_1M%M
	Save_Settings_TandTemp(%0)
	ljmp Preset_Not_3M%M
	
Preset_Not_1M%M:
	cjne a, #0x02, Preset_Not_2M%M
	Save_Settings_TandTemp(%1)
	ljmp Preset_Not_3M%M
	
Preset_Not_2M%M:
	cjne a, #0x03, Preset_Not_3M%M
	Save_Settings_TandTemp(%2)
	ljmp Preset_Not_3M%M
	
Preset_Not_3M%M:
	pop acc
	endmac

;------------------------------;
;Menu_Null
;------------------------------;
;The necessary function that gets used when using less than 4 branches (A filler)
Menu_Null:
	ret
;------------------------------;
;Menu_Back
;------------------------------;
;The necessary function that gets used when wanted to return from a level of the menu
Menu_Back:
	mov R0, #0x01	;sets the flag for the program to know to exit
	ret

;------------------------------;
;Print_FSM_Info
;------------------------------;
Print_FSM_Info mac
	set_Cursor(1,%1)
	Send_Constant_String(#%0)
	endmac

;------------------------------;
;Hex_to_BCD_Print
;------------------------------;
Hex_to_BCD_Print mac
	mov x +0, %0
	mov x +1, #0x00
	mov x +2, #0x00
	mov x +3, #0x00
	lcall hex2bcd
	set_Cursor(%1,%2)
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	endmac

;------------------------------;
;Print_FSM_Clear_Name
;------------------------------;
;FUNCTION TO CLEAR THE NAME DURING RUNTIME
Print_FSM_Clear_Name:
	set_Cursor(1,7)
	Send_Constant_String(#CLEARHALFLINE)
	set_Cursor(1,9)
	Send_Constant_String(#CLEARHALFLINE)
	ret

;------------------------------;
;FSM_Set_Desired_Temp
;------------------------------;	
FSM_Set_Desired_Temp mac
	mov a,  %0
	mov Set_Temp, a
	endmac

;------------------------------;
;Send_Byte
;------------------------------;
Send_Byte mac
	jnb Tx_Ready, $
	clr Tx_Ready
	mov SBUF, %0
	endmac

;--------------------;
;Probe_Temp
;--------------------;
;aquires the proper probes temp and stores it in a variable to have operations done
;%0 = SPI channel and other, EX: #10000000B
;%1 = variable in memory (2bytes) to store the reading 
;%2 = multiplication correction
;%3 = shift correction
Probe_Temp mac
	clr CE_ADC
	mov R3, #00000001B ; Start bit:1
	lcall DO_SPI_G
	mov R3, %0 ; Single ended, read channel 0
	lcall DO_SPI_G
	mov a, R4 ; R1 contains bits 8 and 9
	anl a, #00000011B ; We need only the two least significant bits
	mov Result+1, a ; Save result high.
	mov R3, #55H ; It doesn't matter what we transmit...
	lcall DO_SPI_G
	mov Result, R4 ; R1 contains bits 0 to 7. Save result low.
	setb CE_ADC
	mov x+3, #0
	mov x+2, #0
	mov x+1, Result+1
	mov x+0, Result
	Load_Y(%2)
	lcall mul32
	Load_Y(100)
	lcall div32
	Load_Y(%3)
	mov a, #%4
	cjne a, #0, add_offset%M
	lcall sub32
	sjmp add_room%M
add_offset%M:
	lcall add32
add_room%M:
	mov y+3, #0
	mov y+2, #0
	mov y+1, Room_Temp+1
	mov y+0, Room_Temp+0
	lcall add32			
	mov %1+1, x+1		;stores temp*100
	mov %1+0, x+0		;stores temp*100
	endmac

;----------------------;
;Place_Calibrated_Temp
;----------------------;
Place_Calibrated_Temp mac
	clr Probe_Flag
	lcall clear_xy
	mov x+1, %0 +1
	mov x+0, %0 +0
	mov y+1, %1 +1
	mov y+0, %1 +0
	lcall add32
	Load_Y(2)
	lcall div32

	mov Calibrated_Result+1, x +1
	mov Calibrated_Result+0, x +0
	endmac
	
Compare_Probes mac
	push AR3	;= buf1
	push AR4	;= buf2
	lcall clear_xy
	mov x+1, %0 +1
	mov x+0, %0 +0
	Load_Y(100)
	lcall div32
	mov R3, x+0
	mov x+1, %1 +1
	mov x+0, %1 +0
	Load_Y(100)
	lcall div32
	mov R4, x+0
	lcall clear_xy
	
	mov x+0, R3
	mov y+0, R4
	lcall sub32				;x contains probebuffer1-probebuffer2
	mov y+0, #%2
	lcall x_lteq_y
	jnb mf, Skip_Probe_Flag1%M
	;setflag
	setb Probe_Flag
	ljmp Done_Compare_Probes%M

 Skip_Probe_Flag1%M:
	lcall clear_xy
 	mov x+0, R4
	mov y+0, R3
	lcall sub32				;x contains probebuffer2-probebuffer1
	mov y+0, #%2
	lcall x_lteq_y
	jnb mf, Skip_Probe_Flag2%M
	;setflag
	setb Probe_Flag
	ljmp Done_Compare_Probes%M
	
 Skip_Probe_Flag2%M:
Done_Compare_Probes%M:
	pop AR4
	pop AR3
	endmac
	



end


