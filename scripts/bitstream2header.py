#!/usr/bin/env python3

import sys
import os.path

BPC = 4156

def column_slicer(columnbits):
    if len(columnbits) > 8:
        head = ["0b" + columnbits[0:8][::-1]] 
        head.extend(column_slicer(columnbits[8::]))
        return head
    if len(columnbits) == 8:
        return ["0b" + columnbits[::-1]]
    if len(columnbits) < 8:
        return ["0b" + "0" * (8 - len(columnbits)) + columnbits[::-1]]

def write_column(f, column, columnname):
    f.write("\nconst uint8_t {:s}[] = {{\n".format(columnname))
    for i in column:
        f.write("    {:},\n".format(i))
    f.write("};\n")

with open(sys.argv[1], 'r') as bitsfile:
    rawbitstream = bitsfile.read()
    stream2 = column_slicer(rawbitstream[0:BPC])
    stream1 = column_slicer(rawbitstream[BPC:2*BPC])
    stream0 = column_slicer(rawbitstream[BPC*2:3*BPC])
    with open(sys.argv[2], 'w') as headerfile:
        defname = os.path.splitext(os.path.basename(sys.argv[2]))[0].upper().replace(".", "_")
        headerfile.write("#ifndef __{:}_\n".format(defname))
        headerfile.write("#define __{:}_\n".format(defname))
        headerfile.write("#define BITS_PER_COLUMN ({:})\n\n".format(BPC))

        write_column(headerfile, stream0, "column0")
        write_column(headerfile, stream1, "column1")
        write_column(headerfile, stream2, "column2")

        headerfile.write("#endif\n")
