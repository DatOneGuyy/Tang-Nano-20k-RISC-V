import time

def collatz():
    num = 1115

    while (num != 1):
        if (num % 2 == 0):
            num /= 2
        else:
            num = num * 3 + 1

start = time.perf_counter_ns()
collatz()
end = time.perf_counter_ns()

print(f"Time elapsed: {end - start}ns")