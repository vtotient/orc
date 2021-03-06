 ; serial&thermo.inc
 ; This file includes functions that can be used for Serial transmission and temperature sensing (using K-type thermocoupler) in 8051
 ; Created by Gilbert Tan, some code segments come from Dr. Jesus Calvo-Fraga
 
 
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
	
	
take_instruction:
	jnb acc.7, take_command
	jnb acc.1, check_ps2
	mov Current_Preset, #1
	ret
check_ps2:
	jnb acc.2, check_ps3
	mov Current_Preset, #2
	ret
check_ps3:
	jnb acc.2, check_ps4
	mov Current_Preset, #3
	ret
check_ps4:
	ret
	
take_command:
	mov c, acc.6
	mov Remote_Start, c
	mov c, acc.5
	mov Remote_Stop, c
	mov c, acc.4
	mov Remote_Data, c
	mov c, acc.3
	mov Remote_STemp, c
	mov c, acc.2
	mov Remote_Stime, c
	mov c, acc.1
	mov Remote_RTemp, c
	mov c, acc.0
	mov Remote_Rtime, c
	ret


	
	

push_math32:
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
	mov a, mf
	push acc
	ret
	
pop_math32:
	pop acc
	mov mf, a
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
	ret
		
update_bounds:
	mov a, Set_Temp
	dec a
	mov lower_bound, a
	add a ,#2
	mov upper_bound, a
	subb a, #11
	mov early_stop_timer, #20
	Load_y(#180)
	lcall x_lt_y
	jnb mf, high_temp
	subb a, #10
	mov early_stop_timer, #30
high_temp:
	mov early_stop_bound, a
	ret

compute_duty_cycle:
	Load_y(#100)
	lcall mul32
	mov y+1, Room_Temp+1
	mov y+0, Room_Temp+0
	lcall sub32
	Load_y(#1543)
	lcall mul32
	Load_y(#10000)
	lcall div32
	mov computed_DC, x
	ret
	
clear_xy:
	clr a
	mov x+3, a
	mov x+2, a
	mov x+1, a
	mov y+3, a
	mov y+2, a
	mov y+1, a
	ret

thermocontrol:
	jnb change_temperature_flag, enter_states
	clr change_temperature_flag
	lcall clear_xy
	mov x+0, Set_Temp
	Load_y(#50)
	lcall x_lt_y
	jb mf, cd_mode
	lcall update_bounds
	lcall compute_duty_cycle
	setb full_power_flag
	clr early_stop_flag
	clr PWM_flag
	sjmp enter_states
cd_mode:
	clr full_power_flag
	clr early_stop_flag
	clr PWM_flag
	
enter_states:
	jb full_power_flag, full_power
	jb early_stop_flag, early_stop
	jb PWM_flag, PWM_mode
	mov Duty_Cycle, #0
	sjmp set_pulse_width
full_power:
	clr a
	lcall clear_xy
	mov x+0, Temp
	mov y+0, early_stop_temp
	lcall x_lt_y
	jnb start_early_stop
	mov Duty_Cycle, #100
	sjmp set_pulse_width
start_early_stop:
	clr full_power_flag
	setb early_stop_flag
	clr PWM_flag
early_stop:
	djnz early_stop_timer, throttling
	sjmp start_PWM
throttling:
	mov Duty_Cycle, #0
	sjmp set_pulse_width
start_PWM:
	mov Duty_Cycle, computed_DC
	lcall clear_xy
	mov x, Temp
	mov y, upper_bound
	lcall x_gteq_y
	jb mf, reduce_power
	mov y, lower_bound
	lcall x_lt_y
	jb mf, increase_power
	sjmp set_pulse_width
increase_power:
	mov a, Duty_Cycle
	add a, #5
	mov Duty_Cycle, a
	sjmp set_pulse_width
reduce_power:
	mov a, Duty_Cycle
	subb a, #5
	mov Duty_Cycle, a

set_pulse_width:
	mov Width_Count, Duty_Cycle
	ret
	
	
	

PWM:
	mov a, Width_Count
	cjne a, #0, Turn_on
	mov Width_Count, a
	setb P_out
	sjmp PWM_Done
Turn_on:
	;cpl p3.6
	dec a
	mov Width_Count, a
	clr P_out
PWM_Done:
	ret
	
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
    
Timer0_Done_0:
	lcall pop_math32
	reti
Timer0_ISR:
	clr p3.7
	lcall push_math32
	sjmp Timer0_Done_0
	djnz Count10ms, Acquire_Temp
	mov Count10ms, #5
	lcall PWM
	mov x+3, #0
	mov x+2, #0
	mov x+1, #0
	mov x+0, Duty_Cycle
	lcall hex2bcd
	mov DC_BCD+1, bcd+1
	mov DC_BCD+0, bcd+0
Acquire_Temp:
	djnz Count2ms, Timer0_Done_0
	mov Count2ms, #250
	clr CE_ADC
	mov R3, #00000001B ; Start bit:1
	lcall DO_SPI_G
	mov R3, #10000000B ; Single ended, read channel 0
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
	Load_Y(2420)
	lcall mul32
	Load_Y(100)
	lcall div32
	Load_Y(30000)
	lcall sub32
	Load_Y(2460)
	lcall add32
	mov Result+1, x+1
	mov Result+0, x+0
	lcall hex2bcd
	Set_Cursor(2,1)
	Display_BCD(bcd+1)
	Display_char(#'.')
	Display_BCD(bcd)
	Set_Cursor(2,5)
	Display_char(#'C')
	;Send_BCD(bcd+2)
	;Send_BCD(bcd+1)
	;mov a, #'.'
	;lcall putchar
	;Send_BCD(bcd+0)
	;mov a, #' '
	;lcall putchar
	;Send_BCD(Set_Temp+1)
	;mov a, #'.'
	;lcall putchar
	;Send_BCD(Set_Temp+0)
	;mov a, #'\r'
	;lcall putchar
	;mov a, #'\n'
	;lcall putchar
	lcall create_packet
	;setb pack_to_send
	
	cpl One_Sec
	jnb One_Sec, Timer0_Done
	;cpl P3.6
	mov a, Duty_Cycle
	mov Width_Count, a
;	lcall thermostat
;	lcall auto_thermo
Timer0_Done:
	lcall pop_math32
	reti
