import os
import sys

programs = []
for file in os.listdir():
    if ".hex" in file:
        programs.append(file)
        f = open(file, "r")
        print(f)

print("Found programs: ")
print(programs)

import sys
import os

def create_mi_file(input_filename, output_filename, ram_depth=16384, ram_width=32):
    """
    Converts a binary file into a Gowin-compatible .mi (Memory Initialization) file.

    Args:
        input_filename (str): The name of the binary file to read.
        output_filename (str): The name of the .mi file to create.
        ram_depth (int): The total number of addresses in the RAM (e.g., 16384).
        ram_width (int): The bit-width of each RAM word (e.g., 32).
    """
    
    # Calculate the number of bytes per memory word
    # e.g., 32 bits / 8 bits/byte = 4 bytes
    try:
        if ram_width % 8 != 0:
            raise ValueError("RAM width must be a multiple of 8.")
        
        bytes_per_word = ram_width // 8
        
        print(f"Starting conversion of '{input_filename}' to '{output_filename}'...")
        print(f"RAM Geometry: Depth={ram_depth}, Width={ram_width} bits ({bytes_per_word} bytes/word)")

        # Open the input and output files
        with open(input_filename, 'rb') as f_in:
            with open(output_filename, 'w') as f_out:
                
                # --- Write .mi File Header ---
                f_out.write(f"#File_format=Hex\n")
                f_out.write(f"#Address_depth={ram_depth}\n")
                f_out.write(f"#Data_width={ram_width}\n")

                address = 0
                # Pre-calculate the format string for hex output, e.g., "08X" for 32-bits
                hex_format_string = f"0{bytes_per_word*2}X"
                
                # --- Process the Binary File ---
                while address < ram_depth:
                    # Read one word's worth of bytes (e.g., 4 bytes)
                    chunk = f_in.read(bytes_per_word)
                    
                    # If the chunk is empty, we've reached the end of the input file
                    if not chunk:
                        break # Stop reading
                        
                    # If the chunk is partial (at the end of the file),
                    # pad it with zeros to make a full word.
                    if 0 < len(chunk) < bytes_per_word:
                        print(f"Warning: Input file ended mid-word. Padding address {address:X} with zeros.")
                        chunk = chunk.ljust(bytes_per_word, b'\x00')
                    
                    # Convert the 4-byte chunk into a single integer.
                    # We assume 'little' endian, which is standard for most
                    # modern CPUs (x86, ARM).
                    data_value = int.from_bytes(chunk, byteorder='little')
                    
                    # Write the formatted line "ABCDEF12"
                    f_out.write(f"{data_value:{hex_format_string}}\n")
                    
                    address += 1

                # --- Fill Remaining RAM with Zeros ---
                if address < ram_depth:
                    print(f"Input file was smaller than RAM. Filling remaining {ram_depth - address} addresses with zeros.")
                    # Create the zero-data string, e.g., "00000000"
                    zero_data_string = "0" * (bytes_per_word * 2)
                    while address < ram_depth:
                        f_out.write(f"{zero_data_string}\n")
                        address += 1
                
                # --- No File Footer in this format ---
                # f_out.write("END;\n")

        print(f"\nSuccessfully created '{output_filename}'.")

    except FileNotFoundError:
        print(f"Error: Input file '{input_filename}' not found.", file=sys.stderr)
    except PermissionError:
        print(f"Error: Do not have permission to write to '{output_filename}'.", file=sys.stderr)
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)

create_mi_file(programs[0], "program1.mi")