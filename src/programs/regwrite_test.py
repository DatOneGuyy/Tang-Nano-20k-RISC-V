file = open("regwrite_test.asm", "w")

for i in range(1, 32):
    file.write(f"addi x{i}, x0, {i}\n")

for i in range(31, 0, -1):
    file.write(f"add x{i}, x{i}, x{32 - i}\n")