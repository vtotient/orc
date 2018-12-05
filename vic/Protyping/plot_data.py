import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sys, time, math

import fetch_data

xsize=100

def data_gen():
    t = data_gen.t
    while True:
       t+=1
       val = fetch_data.get_temp()
       yield t, val

def run(data):
    # update the data
    t,y = data
    if t>-1:
        xdata.append(t)
        ydata.append(y)
        if t>xsize: # Scroll to the left.
            ax.set_xlim(t-xsize, t)
        line.set_data(xdata, ydata)
        line2.set_data(xdata, [y*2 for y in ydata])

    return line,

def on_close_figure(event):
    sys.exit(0)


data_gen.t = -1
fig = plt.figure()
fig.canvas.mpl_connect('close_event', on_close_figure)
ax = fig.add_subplot(111)
line, = ax.plot([], [], lw=2, color='blue')
line2, = ax.plot([], [], lw=2, color='red')
ax.set_ylim(10, 300)
ax.set_xlim(0, xsize)
ax.grid()
xdata, ydata = [], []

# Important: Although blit=True makes graphing faster, we need blit=False to prevent
# spurious lines to appear when resizing the stripchart.
ani = animation.FuncAnimation(fig, run, data_gen, blit=False, interval=100, repeat=False)
plt.show()
