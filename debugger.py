import serial
import argparse

parser = argparse.ArgumentParser(description="fpga debugger")

parser.add_argument('--hex', action='store_true')
parser.add_argument('--bin', action='store_true')
parser.add_argument('--str', action='store_true')
parser.add_argument('--sint', action='store_true')

args = parser.parse_args()

uart = serial.Serial()
uart.baudrate = 115200
uart.port = 'COM11'

uart.open()

buffer = []
while (True):
    received_byte = uart.readline(1)
    buffer.append(received_byte)
    if len(buffer) == 137:
        # Take only the last 4 bytes for a 32-bit integer
        data = int.from_bytes(b"".join(buffer[-5:-1]), byteorder="big")
        signed_data = int.from_bytes(b"".join(buffer[-5:-1]), byteorder="big", signed=True)
        pure_string = "".join([c.decode("iso-8859-1") for c in buffer])[:-9]
        output_line = pure_string
        if args.bin:
            output_line = output_line + bin(data)
        elif args.hex:
            output_line = output_line + "0x" + hex(data).upper()[2:]
        elif args.str:
            data_str = "".join([c.decode("iso-8859-1") for c in buffer])[-9:-1]
            output_line = output_line + data_str
        elif args.sint:
            output_line = output_line + str(signed_data)
        else:
            output_line = output_line + str(data)
        
        print(output_line)
        
        buffer = []

    