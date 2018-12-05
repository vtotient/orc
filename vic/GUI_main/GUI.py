from appJar import gui 
import os
import math 
import gen_purpose_str as st
import data_transmition as dt
import voice_controls as vc 
import sms 


MAX_TEMP  = 400
SAFE_TEMP_HI = 60.0 

state_encodings = {
    0: st.ready, 
    1: st.state1, 
    2: st.state2,
    3: st.state3, 
    4: st.state4, 
    5: st.state5
    }

def decode_command(command):
    if command == "what is the temperature" or command == "whats the temperature" or command == "temperature":
        app.infoBox("Voice Commands", "The temperature is" + str(dt.get_temp()))

    # User wants to start
    elif "start" in command or "begin" in command:
        dt.encode("Start")

        try:
            sms.send_text("Your oven is now in progress")
        except:
            print("Error sending text: voice start")

    # User wants to stop
    elif "abort" in command or "stop" in command:
        dt.encode("Abort")

        try:
            sms.send_text("The oven was aborted")
        except:
            print("Error sending text: voice abort")

    # User wants to know what temperature is
    elif "temperature" in command and ("tell" in command or "give" in command or "what" in command or "whats" in command):
    	print(dt.get_temp())

    # User wants to set soak or reflow temperature
    elif "temperature" in command and ("set" in command or "make" in command or "be" in command or "want" in command):
    	if "soak" in command:
    		try:
    			soak_temp_val = [int(s) for s in command.split() if s.isdigit()][0]
    			dt.PC2MCU_GISA("Soak Temp", soak_temp_val)
    		except:
    			print('Error: couldn\'t extract and/or send soak temperature')
    	elif "reflow" in command:
    		try:
    			reflow_temp_val = [int(s) for s in command.split() if s.isdigit()][0]
    			dt.PC2MCU_GISA("Reflow Temp", reflow_temp_val)
    		except:
    			print('Error: couldn\'t extract and/or send reflow temperature')

    # User wants to set soak or reflow time
    elif "time" in command and ("set" in command or "make" in command or "be" in command or "want" in command):
    	if "soak" in command:
    		try:
    			soak_time_val = [int(s) for s in command.split() if s.isdigit()][0]
    			dt.PC2MCU_GISA("Soak Time", soak_time_val)
    		except:
    			print('Error: couldn\'t extract and/or send soak time')
    	elif "reflow" in command:
    		try:
    			reflow_time_val = [int(s) for s in command.split() if s.isdigit()][0]
    			dt.PC2MCU_GISA("Reflow Time", reflow_time_val)
    		except:
    			print('Error: couldn\'t extract and/or send reflow time')


def press(button):
    if button == "Close":
        app.stop()

    elif button == "Start":
        dt.encode("Start")
        try:
            sms.send_text("Your oven is now in progress")
        except:
            print("Error sending text: start button")


    elif button == "Plot":
        app.thread(plotter)

    elif button == "Abort":
        dt.encode("Abort")
        try:
            sms.send_text("Oven is aborted")
        except:
            print("Error sending text: abort button")


    elif button == "Apply":
        try:
            opcode_type = app.getOptionBox("Settings_option_box")
            print(opcode_type)
        except:
            print("Exception: can't fetch opcode type")
            return 

        try:
            data_sec = app.getSpinBox("Time_spin_box")
        except:
            print("Exception: can't fetch seconds from spinbox")
            return

        try:
            data_temp = app.getSpinBox("Temp_spin_box")
        except:
            print("Exception: can't fetch temperature from spinbox")
            return

        if opcode_type == "Reflow":

            try:
                dt.PC2MCU_GISA("Reflow Time", data_sec)
                dt.PC2MCU_GISA("Reflow Temp", data_temp)
            except:
                print("Exception: Can't send Reflow time")
                return

        elif opcode_type == "Soak":
            """print(data_sec)
            print(data_temp)"""
            try:
                dt.PC2MCU_GISA("Soak Time", data_sec)
                dt.PC2MCU_GISA("Soak Temp", data_temp)
            except:
                print("Exception: Can't send Soak time")
                return

    elif button == "Voice":
        command = str(vc.voice_rec())
        decode_command(command)

    

def updateMeter():

    current_temp = -1

    try:
        current_temp = dt.get_temp()
        app.setMeter("Temperature", (current_temp /MAX_TEMP)*100)
    except:
        pass

    try:
        state = dt.get_state()
        app.setMeter("Progress_bar", (state-1)*20)
    except:
        pass

    if current_temp >= MAX_TEMP:
        user_abort = app.yesNoBox("ABORT", "MAXMIMUM TEMPERATURE HIT\n\nUser abort now", None) 

        if user_abort:
            dt.encode("Abort")
            try:
                sms.send_text("Maximum temperature hit. Oven aborted.")
            except:
                print("Error sending text: Max temp abort")

    user_selected_preset = app.getOptionBox("Presets")

    if user_selected_preset == "1":
        try:
            dt.encode("Preset1")
        except:
            print("Handling exception: encoding Preset1")
    elif user_selected_preset == "2":
        try:
            dt.encode("Preset2")
        except:
            print("Handling exception: encoding Preset2")
    elif user_selected_preset == "3":
        try:
            dt.encode("Preset3")
        except:
            print("Handling exception: encoding Preset3")



def plotter():
    bash_command = "python data_plot.py"
    os.system(bash_command)


def fetch_data():
    dt.get_data()


def update():
    try:
        app.thread(dt.get_data())
    except:
        temp, tot, state_tim, state, err_code = -1, -1, -1, -1 , -1  

    temp      = dt.get_temp()
    tot       = dt.get_state_counter()
    state_tim = dt.get_counter()
    state     = int(dt.get_state())
    err_code  = dt.get_err_code()
    app.setLabel("Temp_display", temp)

    if state == 0:
        app.setStatusbarBg("white")
        app.setLabel("time1", "0")
        app.setLabel("time2", "0")
    else:    
        app.setLabel("time1", state_tim)
        app.setLabel("time2", tot)


    try:
        app.setLabel("State", state_encodings[state])
    except:
        print("Handling exception: setting state Progress_label")

    if state == 0:
        app.setStatusbar(st.ready,0)
    elif state == 5 and temp < SAFE_TEMP:
        app.setStatusbar(st.safe, 0)
        app.setStatusbarBg("green")
        app.after(5000, app.infoBox("Safe_Box", st.safe))
        #sms.send_text("Cycle ended, PCB safe to touch")
    else:
        app.setStatusbar(st.progress,0)



    if err_code == 0:
        app.setStatusbar("No warnings", 1)
        app.setStatusbarBg("green",1)

    elif err_code == 1:
        app.setStatusbar("Check oven: may be accidentally on", 1)
        app.after(5000, app.setStatusbarBg("yellow" ,1))

    elif err_code == 2:
        app.setStatusbar("Oven failed to reach correct temp", 1)
        app.setStatusbarBg("red",1)

    elif err_code == 3:
        # app.setStatusbar("Probe one and two temperatures mismatch", 1)
        # app.setStatusbarBg("yellow",1)
        pass

    elif err_code == 4:
        app.setStatusbar("Probe failure, check probe positions", 1)
        app.setStatusbarBg("red",1)
        #app.infoBox("infoBox4", "Oven door open")

    elif err_code == 5:
        app.setStatusbar("Oven door open for too long", 1)
        app.setStatusbarBg("yellow",1)

    else:
        app.setStatusbar("Unknown error", 1)
        app.setStatusbarBg("orange",1)
        


def menu_about():    
   app.showSubWindow("About_sub_win")

def menu_about_us():
    app.showSubWindow("About_us_win")


def looper():
    dt.get_data()

# app configurations:
# create a GUI variable called app
app = gui("Oven Reflow Controller", "1000x700")
app.setBg("white")
app.setSticky("news")
app.setExpand("both")
app.setFont(18)
app.registerEvent(looper)

# Splash Screen:
app.showSplash("F.R.O.G", fill='while', stripe='blue', fg='white', font=44)


# Need to fetch data constantly
app.registerEvent(fetch_data)
app.registerEvent(updateMeter)
app.registerEvent(update)

# Menus
app.createMenu("Menu")
app.addMenuItem("Menu", "Docs", menu_about)
app.addMenuItem("About us", menu_about_us)


app.startSubWindow("About_sub_win", modal = False)
app.addImage("data_sheet", "DataSheet.gif",)
app.stopSubWindow()

app.startSubWindow("About_us_win", modal=False)
app.addImage("about_us","about_us.gif")
add.stopSubWindow("About_us_win")


# Temperature 
app.addMeter("Temperature", 1, 0)
app.setMeterFill("Temperature", "red")
app.addLabel("Temp_Lb","Oven Temperature", 0, 1)
app.addLabel("Temp_display", st.load_str, 1, 2)

# Progress 
app.addLabel("Progress_label", "Progress", 2, 1)
app.addMeter("Progress_bar",3,0)
app.setMeterFill("Progress_bar","blue")
app.addLabel("State", st.load_str, 3, 2)

# Run Time
myString3 =" hello"
app.addLabel("Rn_lb", "Run Time", 5, 1)
app.addLabel("tot_lb","Total", 6,0)
app.addLabel("st_lb","State", 6,2)
app.addLabel("time1", st.load_str, 7,0)
app.addLabel("time2", st.load_str, 7,2)

# Option Box
# app.addLabelOptionBox("Settings", ["Soak", "Reflow"], 8, 0)
# app.addLabelSpinBoxRange("Seconds", 0,60, 8,1)
# app.addLabelSpinBoxRange("Temp", 100, 200, 8, 2)
app.addButtons(["Apply"], press, 9, 1)
app.addOptionBox("Settings_option_box", ["Soak", "Reflow"], 8, 0)
app.addSpinBox("Temp_spin_box", list(range(1,270)), 8, 1)
app.addSpinBox("Time_spin_box", list(range(0, 59)), 8, 2)

app.addLabelOptionBox("Presets", ['1','2','3'], 10, 0)


app.setPadding([20,20])


# link the buttons to the function called press
app.addButtons( ["Plot", "Abort", "Start", "Voice"], press, 11, 1)


# Status Bar
myString = "Ready"
myString2 = "Cool to touch"
app.addStatusbar(fields=2)
app.setStatusbar(st.empty)
app.setStatusbar(st.empty, 1)


# start the GUI
while True:
    try:
        dt.get_data()
        app.go()
        break
    except:
        print("Exception: stalling, serial port is not ready to transmit")