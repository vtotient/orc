import serial
import serial.tools.list_ports

PORT = '/dev/tty.usbserial-DN036QAR'

def get_data():
    try:
        ser.close();
    except:
        print();
    try:
        ser = serial.Serial(PORT, 115200, timeout=100)
    except:
        print ('Fetch_data Error: Serial port %s is not available' % PORT);
        portlist=list(serial.tools.list_ports.comports())
        print('Trying with port %s' % portlist[0][0]);
        ser = serial.Serial(portlist[0][0], 115200, timeout=100)
        ser.isOpen()

    return strin = ser.readline();

def send_data():
    