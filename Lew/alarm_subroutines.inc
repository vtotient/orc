cseg

;-------------------------
; Check_Alarms Subroutine
;-------------------------
Check_Alarms:
	setb RS0

	jnb flag_one, Inc_Count_two
	inc r0 ; Count_one+0
	mov a, r0 ; Count_one+0
	jnz Inc_Count_two
	inc r1 ; r1
	
Inc_Count_two:
	jnb flag_two, Inc_Count_three
	inc r2
	mov a, r2
	jnz Inc_Count_three
	inc r3
	
Inc_Count_three:
	jnb flag_three, Check_Count_one
	inc r4
	mov a, r4
	jnz Check_Count_one
	inc r5

Check_Count_one:
	mov a, r0
	cjne a, #low(150), Check_Count_two
	mov a, r1
	cjne a, #high(150), Check_Count_two
	
	; SHORT ALARM TURNS OFF HERE
	
	cpl TR1
	setb SOUND_OUT ; Shut off current to the speaker
	clr flag_one
	clr a
	mov r0, a
	mov r1, a
	
Check_Count_two:
	mov a, r2
	cjne a, #low(750), Check_Count_three
	mov a, r3
	cjne a, #high(750), Check_Count_three

	; LONG ALARM TURNS OFF HERE

	cpl TR1
	setb SOUND_OUT ; Shut off current to the speaker
	clr flag_two
	clr a
	mov r2, a
	mov r3, a
	
Check_Count_three:
	mov a, r4
	cjne a, #low(100), Check_Count_three_2
	mov a, r5
	cjne a, #high(100), Check_Count_three_2
	cpl TR1
Check_Count_three_2:
	mov a, r4
	cjne a, #low(200), Check_Count_three_3
	mov a, r5
	cjne a, #high(200), Check_Count_three_3

	; If you want to change the pitch
	; mov TH1, #high(65536-(CLK/(2637*2)))
	; mov TL1, #low(65536-(CLK/(2637*2)))
	; mov TIMER1_RELOAD_H, #high(65536-(CLK/(2637*2)))
	; mov TIMER1_RELOAD_L, #low(65536-(CLK/(2637*2)))

	cpl TR1
Check_Count_three_3:
	mov a, r4
	cjne a, #low(300), Check_Count_three_4
	mov a, r5
	cjne a, #high(300), Check_Count_three_4
	cpl TR1
Check_Count_three_4:
	mov a, r4
	cjne a, #low(400), Check_Count_three_5
	mov a, r5
	cjne a, #high(400), Check_Count_three_5
	cpl TR1
Check_Count_three_5:
	mov a, r4
	cjne a, #low(500), Check_Count_three_6
	mov a, r5
	cjne a, #high(500), Check_Count_three_6
	cpl TR1
Check_Count_three_6:
	mov a, r4
	cjne a, #low(600), Check_Count_three_7
	mov a, r5
	cjne a, #high(600), Check_Count_three_7
	cpl TR1
Check_Count_three_7:
	mov a, r4
	cjne a, #low(700), Check_Count_three_8
	mov a, r5
	cjne a, #high(700), Check_Count_three_8
	cpl TR1
Check_Count_three_8:
	mov a, r4
	cjne a, #low(800), Check_Count_three_9
	mov a, r5
	cjne a, #high(800), Check_Count_three_9
	cpl TR1
Check_Count_three_9:
	mov a, r4
	cjne a, #low(900), Check_Count_three_10
	mov a, r5
	cjne a, #high(900), Check_Count_three_10
	cpl TR1
Check_Count_three_10:
	mov a, r4
	cjne a, #low(1000), Check_Count_three_11
	mov a, r5
	cjne a, #high(1000), Check_Count_three_11
	cpl TR1
Check_Count_three_11:
	mov a, r4
	cjne a, #low(1100), Alarm_Subroutine_Done
	mov a, r5
	cjne a, #high(1100), Alarm_Subroutine_Done
	cpl TR1
	
	; BEEPING ALARM TURNS OFF HERE
	
	setb SOUND_OUT ; Shut off current to the speaker	
	clr flag_three
	clr a
	mov r4, a
	mov r5, a

Alarm_Subroutine_Done:
	clr RS0
	ret

;--------------------------------
; Trigger_Short_Alarm Subroutine
;--------------------------------
Trigger_Short_Alarm:
	setb RS0
	clr a
	mov r0, a
	mov r1, a
	setb flag_one
	cpl TR1
	clr RS0
	ret

;--------------------------------
; Trigger_Long_Alarm Subroutine
;--------------------------------
Trigger_Long_Alarm:
	setb RS0
	clr a
	mov r2, a
	mov r3, a
	setb flag_two
	cpl TR1
	clr RS0
	ret

;--------------------------------
; Trigger_Beeping_Alarm Subroutine
;--------------------------------
Trigger_Beeping_Alarm:
	setb RS0
	clr a
	mov r4, a
	mov r5, a
	setb flag_three
	cpl TR1
	clr RS0
	ret

;--------------------------------
; Reset_Alarms Subroutine
;--------------------------------
Reset_Alarms:
	setb RS0
	clr a
	mov r0, a
	mov r1, a
	mov r2, a
	mov r3, a
	mov r4, a
	mov r5, a
	clr flag_one
	clr flag_two
	clr flag_three
	clr TR1
	clr RS0
	ret
	