from tkinter import *
import data_transmition as dt

root = Tk()

# Frame:
topFrame = Frame(root)
bottomFrame = Frame(root)

# Buttons:
bt_close = Button(bottomFrame, text="Close")
bt_abort = Button(bottomFrame, text="Abort")

# Labels:
lb_temp = Label(root, text="Temperature")
lb_state = Label(root, text="Current State")


# Pack and Display:
topFrame.pack()
bottomFrame.pack(side=BOTTOM)
bt_close.pack(side=BOTTOM)
bt_abort.pack(side=TOP)
lb_temp.pack(fill=Y, side=RIGHT)
lb_state.pack(side=LEFT, fill=Y)

root.mainloop()