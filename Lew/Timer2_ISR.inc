$NOLIST
;this file contains timer2 ISR and the initialization of it
;also has the code that gets the tempurature from multiple probes

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
	
Timer1_ISR:
	cpl SOUND_OUT
	reti

;---------------------------------;
; Routine to initialize the ISR  
; for timer 2                     
;---------------------------------;
Timer2_Init:
	mov T2CON, #0 ; Stop timer/counter.  Autoreload mode.
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	; Set the reload value
	mov RCAP2H, #high(TIMER2_RELOAD)
	mov RCAP2L, #low(TIMER2_RELOAD)
	; Init One millisecond interrupt counter.  It is a 16-bit variable made with two 8-bit parts
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Enable the timer and interrupts
    setb ET2  ; Enable timer 2 interrupt
    ;setb PT2
    setb TR2  ; Enable timer 2
	ret		
	
;---------------------------------;
; ISR for timer 2                 
;---------------------------------;
Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
	setb P3.6 ; To check the interrupt rate with oscilloscope. It must be precisely a 1 ms pulse.
	; The two registers used in the ISR must be saved in the stack
	push acc
	push psw
	
	
	mov a, x+3
	push acc
	mov a, x+2
	push acc
	mov a, x+1
	push acc
	mov a, x+0
	push acc
	mov a, y+3
	push acc
	mov a, y+2
	push acc
	mov a, y+1
	push acc
	mov a, y+0
	push acc
	mov a, bcd+4
	push acc
	mov a, bcd+3
	push acc
	mov a, bcd+2
	push acc
	mov a, bcd+1
	push acc
	mov a, bcd+0
	push acc
	mov c, mf
	push psw
	
	; Increment the 16-bit one mili second counter
	inc Count1ms+0    ; Increment the low 8-bits first
	mov a, Count1ms+0 ; If the low 8-bits overflow, then increment high 8-bits
	jnz Inc_Done
	inc Count1ms+1

Inc_Done:
	; Check if half second has passed
	mov a, Count1ms+0
	cjne a, #low(500), Timer2_ISR_done ; Warning: this instruction changes the carry flag!
	mov a, Count1ms+1
	cjne a, #high(500), Timer2_ISR_done
	
	; 500 milliseconds have passed.  Set a flag so the main program knows
	setb half_seconds_flag ; Let the main program know half second had passed
	; Reset to zero the milli-seconds counter, it is a 16-bit variable
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Increment the BCD counter
	
	mov a, oven_state
	cjne a, #0, BCD_counter_increment
	mov BCD_state_counter+0, #0
	mov BCD_state_counter+1, #0
	mov BCD_counter+0, #0
	mov BCD_counter+1, #0
	sjmp Skip_Cpl_State_Flag
BCD_counter_increment:
	mov a, BCD_counter+0
	add a, #0x01
	da a ; Decimal adjust instruction.  Check datasheet for more details!
	mov BCD_counter+0, a	
	;now checking if overflow
	cjne a, #0x00, BCD_counter_No_Overflow
	mov a, BCD_counter+1
	add a, #0x01
	da a
	mov BCD_counter+1, a
	
BCD_counter_No_Overflow:
	; Increment the BCD state counter
	mov a, BCD_state_counter
	add a, #0x01
	da a ; Decimal adjust instruction.  Check datasheet for more details!
	mov BCD_state_counter, a
	cjne a, #0x00, BCD_state_counter_No_Overflow
	mov a, BCD_state_counter+1
	add a, #0x01
	da a
	mov BCD_state_counter+1, a

	
BCD_state_counter_No_Overflow:
	
	;the operations working with the runtime display
	mov a, state_flag_counter
	INC state_flag_counter
	cjne a, #0x05, Skip_Cpl_State_Flag
	cpl state_display_flag
	setb state_display_flag2
	mov state_flag_counter, #0x00
Skip_Cpl_State_Flag:

Timer2_ISR_done:
	lcall Check_Alarms
	sjmp Timer2_ISR2
   
Timer2_Done_2:
	;clr P3.6
	
	pop psw
	mov mf, c
	pop acc
	mov bcd+0, a
	pop acc
	mov bcd+1, a
	pop acc
	mov bcd+2, a
	pop acc
	mov bcd+3, a
	pop acc
	mov bcd+4, a
	pop acc
	mov y+0, a
	pop acc
	mov y+1, a
	pop acc
	mov y+2, a
	pop acc
	mov y+3, a
	pop acc
	mov x+0, a
	pop acc
	mov x+1, a
	pop acc
	mov x+2, a
	pop acc
	mov x+3, a
	pop psw
	pop acc
	reti
Timer2_ISR2:
	djnz Count10ms, Acquire_Temp
	mov Count10ms, #5
	lcall PWM
	

Acquire_Temp:
	;cpl One_Sec
	;jnb One_Sec, Timer2_Done3
	;cpl One_Sec2
	;jnb One_Sec2,Timer2_Done3
	
	;djnz Count2ms, Timer2_Done3
	;mov Count2ms, #250
	sjmp first_sample
Timer2_Done3:
;	clr P3.6

	pop psw
	mov mf, c
	pop acc
	mov bcd+0, a
	pop acc
	mov bcd+1, a
	pop acc
	mov bcd+2, a
	pop acc
	mov bcd+3, a
	pop acc
	mov bcd+4, a
	pop acc
	mov y+0, a
	pop acc
	mov y+1, a
	pop acc
	mov y+2, a
	pop acc
	mov y+3, a
	pop acc
	mov x+0, a
	pop acc
	mov x+1, a
	pop acc
	mov x+2, a
	pop acc
	mov x+3, a
	pop psw
	pop acc
	reti
first_sample:
	Probe_Temp(#10000000B,Probe3_Temp_Sample1,2463,0,0)	
	Probe_Temp(#10010000B,Probe2_Temp_Sample1,2458,30,1)		;needs last 2 parameters tested
	Probe_Temp(#10100000B,Probe1_Temp_Sample1,2445,300,1)		;needs last 2 parameters tested

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
	
	
	djnz Count2ms, Timer2_Done2
	mov Count2ms, #250
	
	;cpl P3.6
	mov Probe1_Temp+1, Probe1_Temp_Sample2+1
	mov Probe1_Temp+0, Probe1_Temp_Sample2+0
	mov Probe2_Temp+1, Probe2_Temp_Sample2+1
	mov Probe2_Temp+0, Probe2_Temp_Sample2+0
	mov Probe3_Temp+1, Probe3_Temp_Sample2+1
	mov Probe3_Temp+0, Probe3_Temp_Sample2+0
	
	
	lcall Calibrate_Temp
	lcall Send_Packet
	cpl One_Sec
	jnb One_Sec, Timer2_Done2
	lcall thermocontrol				;function contained in "serialthermo.inc"
		
	mov a, oven_state
	cjne a, #0, open_door?
	sjmp close_door?
open_door?:
	cjne a, #5, open_door??
	sjmp close_door?
open_door??:
	jnb DoorPIN, close_door?
	jb Door_Open, Door_Open_Abort
	djnz Door_Open_Timer, Timer2_Done2
Door_Open_Abort:
	orl Error_Codes, #00001000b
	setb Door_Open
	setb abort_flag
	sjmp Timer2_Done2
close_door?:
	mov Door_Open_Timer, #10
	clr Door_Open
	clr abort_flag
Timer2_Done2:
	;clr P3.6
	
	pop psw
	mov mf, c
	pop acc
	mov bcd+0, a
	pop acc
	mov bcd+1, a
	pop acc
	mov bcd+2, a
	pop acc
	mov bcd+3, a
	pop acc
	mov bcd+4, a
	pop acc
	mov y+0, a
	pop acc
	mov y+1, a
	pop acc
	mov y+2, a
	pop acc
	mov y+3, a
	pop acc
	mov x+0, a
	pop acc
	mov x+1, a
	pop acc
	mov x+2, a
	pop acc
	mov x+3, a
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
	orl Error_Codes, #00100000b

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
	
	orl Error_Codes, #00010000b
	
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
	
;--------------------;
;Send_Packet
;--------------------;
Send_Packet:
	;current temp
	Send_Byte(Calibrated_Result+1)	;Calibration_Result is 100*Temp		
	Send_Byte(Calibrated_Result+0)	
	;bcd_counter
	clr a					
	mov bcd+4, a
	mov bcd+3, a
	mov bcd+2, a
	mov bcd+1, BCD_counter+1
	mov bcd+0, BCD_counter+0
	lcall bcd2hex
	Send_Byte(x+1)					;number in the second byte is N*256
	Send_Byte(x+0)					;number in first byte is 0<=N<=255
	;bcd_state_counter
	clr a						
	mov bcd+4, a
	mov bcd+3, a
	mov bcd+2, a
	mov bcd+1, BCD_state_counter+1
	mov bcd+0, BCD_state_counter+0
	lcall bcd2hex
	Send_Byte(x+0)
	;oven_state
	mov a, oven_state
	orl Error_Codes, a
	Send_Byte(Error_Codes)			;lower 3 bits contain binary representation of current state, upper 4 bits contain 1 hot error signals
	mov Error_Codes, #0
	;Send_Byte(#'a')
	;Send_Byte(#'b')
	;Send_Byte(#'c')
	Send_Byte(#'\n')	
	ret
	
end