import serial
import argparse

parser = argparse.ArgumentParser(description="fpga debugger")

parser.add_argument('--hex', action='store_true')
parser.add_argument('--bin', action='store_true')
parser.add_argument('--str', action='store_true')
parser.add_argument('--sint', action='store_true')
parser.add_argument('--double', action='store_true')
parser.add_argument('--rhex', action='store_true')
parser.add_argument('--rbin', action='store_true')
parser.add_argument('--rstr', action='store_true')
parser.add_argument('--rsint', action='store_true')

args = parser.parse_args()

uart = serial.Serial()
uart.baudrate = 230400
uart.port = 'COM11'

uart.open()

def parse_number(byte_string, type="reg"):
    if type == "reg":
        if args.rbin:
            data = bin(int.from_bytes(b"".join(byte_string), byteorder="big"))
        elif args.rhex:
            data = "0x" + hex(int.from_bytes(b"".join(byte_string), byteorder="big")).upper()[2:]
        elif args.rstr:
            data = "".join([c.decode("iso-8859-1") for c in byte_string])
        elif args.rsint:
            data = str(int.from_bytes(b"".join(byte_string), byteorder="big", signed=True))
        else:
            data = str(int.from_bytes(b"".join(byte_string), byteorder="big", signed=False))
    else:
        if args.bin:
            data = bin(int.from_bytes(b"".join(byte_string), byteorder="big"))
        elif args.hex:
            data = "0x" + hex(int.from_bytes(b"".join(byte_string), byteorder="big")).upper()[2:]
        elif args.str:
            data = "".join([c.decode("iso-8859-1") for c in byte_string])
        elif args.sint:
            data = str(int.from_bytes(b"".join(byte_string), byteorder="big", signed=True))
        elif args.double:
            data = str([int.from_bytes(b"".join(byte_string[:4]), byteorder="big", signed=True), int.from_bytes(b"".join(byte_string[4:]), byteorder="big", signed=True)])
        else:
            data = str(int.from_bytes(b"".join(byte_string), byteorder="big", signed=False))
    
    return data

buffer = []
while (True):
    received_byte = uart.readline(1)
    buffer.append(received_byte)
    if len(buffer) == 169:
        label = "".join([c.decode("iso-8859-1") for c in buffer])[128:-9]
        register_values = []
        for i in range(0, 128, 4):
            register_values.append(int(parse_number(buffer[i:i + 4])))

        print(label + parse_number(buffer[-9:-1], "data"))
        if "program counter" not in label:
            print(register_values)

        buffer = []

    