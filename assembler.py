import argparse
import os
import time

r_type = ["add", "sub",  "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu"]
i_type = ["addi", "xori", "ori", "andi", "slli", "srli", "srai", "slti", "sltiu"]
l_type = ["lb", "lh", "lw", "lbu", "lhu"]
s_type = ["sb", "sh", "sw"]
b_type = ["beq", "bne", "blt", "bge", "bltu" ,"bgeu"]
j_type = ["jal", "jalr"]
ui_type = ["lui", "auipc"]

def parse_number(input, length = 12):
    result = 0
    if (input[:2] == "0x"):
        result = int(input[2:], 16)
    elif (input[:2] == "0b"):
        result = int(input[2:], 2)
    elif (input[:2] == "0o"):
        result = int(input[2:], 8)
    elif (input[:2] == "0d"):
        result = int(input[2:])
    else:
        result = int(input)
    
    if (result >= 2 ** (length - 1) or result < (2 ** (length - 1)) * -1):
        print(f"(WARN) Immediate input {input[:-1]} was truncated to length {length}")

    if (result < 0):
        result = result + 2 ** length

    return f"{result:0{length}b}"
    
def parse_register(token):
    dest_number = int(token[1:])
    if (dest_number < 0 or dest_number > 31 or token[0] != "x"):
        return f"e: Invalid destination register {token}"
    else:
        return f"{dest_number:0{5}b}"

funct3_dict = {
    "add": 0,
    "sub": 0,
    "xor": 4,
    "or": 6,
    "and": 7,
    "sll": 1,
    "srl": 5,
    "sra": 5,
    "slt": 2,
    "sltu": 3,
    "addi": 0,
    "xori": 4,
    "ori": 6,
    "andi": 7,
    "slli": 1,
    "srli": 5,
    "srai": 5,
    "slti": 2,
    "sltiu": 3,
    "lb": 0,
    "lh": 1,
    "lw": 2,
    "lbu": 4,
    "lhu": 5,
    "sb": 0,
    "sh": 1,
    "sw": 2,
    "beq": 0,
    "bne": 1,
    "blt": 4,
    "bge": 5,
    "bltu": 6,
    "bgeu": 7, 
    "jal": 0,
    "jalr": 0,
    "lui": 0,
    "auipc": 0
}

def assemble_line(line):
    opcode = "0110011"
    tokens = line.split(" ")
    tokens = [t.replace(",", "") for t in tokens]
    format = None

    inst = tokens[0]
    if (inst in r_type):
        format = "R"
        opcode = "0110011"
    elif (inst in i_type):
        format = "I"
        opcode = "0010011"
    elif (inst in l_type):
        format = "I"
        opcode = "0000011"
    elif (inst in s_type):
        format = "S"
        opcode = "0100011"
    elif (inst in b_type):
        format = "B"
        opcode = "1100011"
    else:
        match inst:
            case "jal": 
                format = "J"
                opcode = "1101111"
            case "jalr":
                format = "I"
                opcode = "1100111"
            case "lui":
                format = "U"
                opcode = "0110111"
            case "auipc":
                format = "U"
                opcode = "0010111"
            case default:
                return f"e: Invalid instruction {inst}"
    
    funct3 = f"{funct3_dict[inst]:0{3}b}"
    funct7 = "0000000"
    if "sra" in inst or "sub" in inst:
        funct7 = "0100000"

    full_string = opcode
    match format:
        case "R":
            rd = parse_register(tokens[1])
            rs1 = parse_register(tokens[2])
            rs2 = parse_register(tokens[3])

            full_string = funct7 + rs2 + rs1 + funct3 + rd + opcode
        case "I":
            rd = parse_register(tokens[1])
            imm = ""
            if (inst[0] == "l"):
                rs1 = parse_register(tokens[2].split("(")[1].split(")")[0])
                imm = parse_number(tokens[2].split("(")[0])
            else:
                rs1 = parse_register(tokens[2])
                imm = parse_number(tokens[3])
                
            if (inst == "slli" or inst == "srli" or inst == "srai"):
                imm = funct7 + imm[-5:]

            full_string = imm + rs1 + funct3 + rd + opcode
        case "S":
            rs2 = parse_register(tokens[1])
            rs1 = parse_register(tokens[2].split("(")[1].split(")")[0])
            imm = parse_number(tokens[2].split("(")[0])

            full_string = imm[:7] + rs2 + rs1 + funct3 + imm[-5:] + opcode
        case "B":
            rs1 = parse_register(tokens[1])
            rs2 = parse_register(tokens[2])
            imm = parse_number(tokens[3], 13)

            full_string = imm[0] + imm[2:8] + rs2 + rs1 + funct3 + imm[8:12] + imm[1] + opcode
        case "J":
            rd = parse_register(tokens[1])
            imm = parse_number(tokens[2], 21)

            full_string = imm[0] + imm[-11:-1] + imm[-12] + imm[1:-12] + rd + opcode
        case "U":
            rd = parse_register(tokens[1])
            imm = parse_number(tokens[2], 20)

            full_string = imm + rd + opcode

    return full_string

start = time.perf_counter_ns()
parser = argparse.ArgumentParser(description="RISC-V assembler")
parser.add_argument("source", help="File name to be parsed")
parser.add_argument("--hex", help="Write output as hex instead of binary", action="store_true")
args = parser.parse_args()

source_file = "src/programs/" + args.source

if (".asm" not in source_file):
    source_file = source_file + ".asm"

read_file = open(source_file, "r")
print(f"Opened source file {source_file}")

destination_file = source_file[:-4] + ".mem"
try:
    os.remove(destination_file)
except FileNotFoundError:
    print("No previous binaries removed")
else:
    print(f"Removed previous binary {destination_file}")
finally:
    print("Beginning assembly")
write_file = open(destination_file, "w")

count = 1
for line in read_file:
    if line == "\n":
        continue
    binary = assemble_line(line)
    if ("e: " in binary):
        print(f"Skipping, error during assembly on line {count}: {binary[3:]}")
    elif (len(binary) != 32):
        print(f"Instruction length mismatch on line {count} with length {len(binary)}")
    else:
        if (args.hex):
            write_file.write(f"{int(binary, 2):0{8}x}\n".upper())
        else:
            write_file.write(binary + "\n")

    count += 1
write_file.write("00000000\n")
end = time.perf_counter_ns()

print(f"Completed assembly and wrote binary to {destination_file}")
print(f"Time taken: {(end - start) / 1000000.0}ms")

read_file.close()
write_file.close()