import serial
import serial.tools.list_ports
import codecs
import numpy as np

#G's board:
#PORT = '/dev/tty.usbserial-DN036Q9K'

#V's board:
#PORT = '/dev/tty.usbserial-DN036QAR'

#L's board:
#PORT = '/dev/tty.usbserial-DN0374C7'

#S's board:
#PORT = '/dev/tty.usbserial-DN036QC9'

PORT = '/dev/tty.HC-05-DevB' 

#PORT = '/dev/tty.HC-05-DevB-1' 

#PORT = '/dev/tty.usbserial-DN0374BS'

encode_table = {
    "Start"        : b'\x80',
    "Abort"        : b'\x40',
    "Preset1"      : b'\x22',
    "Preset2"      : b'\x24',
    "Preset3"      : b'\x28',
    "Soak Temp"    : b'\x18',
    "Soak Time"    : b'\x14',
    "Reflow Temp"  : b'\x12',
    "Reflow Time"  : b'\x11' 
    }

error_code_table = {
    128 : 1,
    64  : 2,
    32  : 3,
    16  : 4,
    8   : 5, 
    0   : 0
}


def get_temp_high():
    return int(x[0])

def get_temp_low():
    return int(x[1])

def get_counter():
    return int(x[2]*256+x[3])

def get_state_counter():
    return int(x[4])

def get_state():
    state = int(x[5])
    return state & 7

def get_err_code():
    err      = int(x[5])
    err_code = bin(err)[2:7]

    if err & 0b00001000:
        return 5
    elif err & 0b10000000:
        return 1
    elif err & 0b00010000:
        return 4
    elif err & 0b01000000:
        return 2
    elif err & 0b00100000:
        return 3
    else:
        return 0


def null_char():
    return int[x[6]] 

def get_temp():
    b1 = get_temp_high()
    b2 = get_temp_low()

    return float(b1*256 + b2)/100

def get_data():
    try:
        ser.close();
    except:
        pass

    try:
        ser = serial.Serial(PORT, 115200, timeout=100)
    except:
        print ('get_data: Serial port %s is not available' % PORT);
        portlist=list(serial.tools.list_ports.comports())
        print('get_data: Trying with port %s' % portlist[0][0]);
        ser = serial.Serial(portlist[0][0], 115200, timeout=100)

    strin = ser.readline()
    

    global x 

    try:
        x = np.fromstring(strin, dtype=np.uint8, count=6)
    except:
        pass 

    try:
        open("data_file.txt", "w").close()
        data_file = open("data_file.txt", "w")
        data_file.write(str(get_temp()))
    except:
        print("Exception: can't write temperature to common root")


def send_data(data):
    try:
        ser.close();
    except:
        pass
    try:
        ser = serial.Serial(PORT, 115200, timeout=100)
    except:
        print ('send_data: Serial port %s is not available' % PORT);
        portlist=list(serial.tools.list_ports.comports())
        print('send_data: Trying with port %s' % portlist[0][0]);
        ser = serial.Serial(portlist[0][0], 115200, timeout=100)

    ser.write(data)

def encode(message):
    mes = str(message) # don't know why this is necessary 

    try:
        byte_to_send = encode_table[mes]
    except:
        print("Error encoding message")  

    try:
        send_data(byte_to_send)  
    except:
        print("Error sending opcode")

def PC2MCU_GISA(opcode, data):
    op = str(opcode)
    dt = int(data)
    
    try:
        print(encode_table[op])
        send_data(encode_table[op])
    except:
        print("Exception: can't encode opcode")
        return

    try:
        print(bytes([dt]))
        send_data(bytes([dt]))
    except:
        print("Exception: can't send data PC2MCU_GISA")
        return

while True:
    try:
        ser = serial.Serial(PORT, 115200, timeout=100)
        break
    except:
        print("Bluetooth transmition not ready, please wait")