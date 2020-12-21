#!/usr/bin/env python3

import sys
import os.path

BITS_PER_TILE = 1039
MX = 7
MY = 8
BPC = MY * BITS_PER_TILE

def column_slicer(columnbits):
    bytes_in_col = []
    num_bytes = int(BPC / 8)
    tail_bits = BPC - num_bytes * 8
    for i in range(num_bytes):
        #bytes_in_col.append("0b" + columnbits[8*(num_bytes-i-1):8*(num_bytes-i)])
        bytes_in_col.append(int(columnbits[8*(num_bytes-i-1):8*(num_bytes-i)], 2))

    if tail_bits > 0:
        #bytes_in_col.append(["0b" + "0" * (8 - tail_bits) + columnbits[0:tail_bits]])
        bytes_in_col.append(int("0b" + "0" * (8 - tail_bits) + columnbits[0:tail_bits], 2))

    return bytes_in_col

def write_column(f, column, columnname):
    f.write("\nconst uint8_t {:s}[] = {{\n".format(columnname))
    for i in column:
        f.write("    {:},\n".format(i))
    f.write("};\n")

with open(sys.argv[1], 'r') as bitsfile:
    rawbitstream = bitsfile.read()
    with open(sys.argv[2], 'w') as headerfile:
        defname = os.path.splitext(os.path.basename(sys.argv[2]))[0].upper().replace(".", "_")
        headerfile.write("#ifndef __{:}_\n".format(defname))
        headerfile.write("#define __{:}_\n".format(defname))
        headerfile.write("#define BITS_PER_COLUMN ({:})\n\n".format(BPC))
        for col in range(MX):
            stream = column_slicer(rawbitstream[BPC*col:BPC*(col+1)])
            write_column(headerfile, stream, "column" + str(col))
        headerfile.write("#endif\n")

