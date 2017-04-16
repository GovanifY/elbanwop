#!/usr/bin/python

import sys
import struct
import os.path

ERR_INVALID_MNEMONIC = "invalid mnemonic: %s"
ERR_INVALID_ARGS = "invalid numbers of arguments (%d) for instruction %s"
ERR_INVALID_REG = "expected register for operand, got: %s"
ERR_INVALID_NUMERIC_OPERAND = "invalid numeric operand found '%d' (must be >=0 and <=0xffff)"
ERR_INVALID_OPERAND_TYPE = "invalid operand found '%s'"

regs = [
    "r0", "r1", "r2", "r3",
    "r4", "r5", "r6", "r7",
    "r8", "r9", "r10", "r11",
    "sp", "lr", "pc"
]

labels = {}
opcodes = []
line_cnt = 0

def err(s):
    print "ERROR (line %d): %s" % (line_cnt, s)
    exit(-1)

def parse_reg(token):
    if token not in regs:
        return False

    return regs.index(token)

def parse_operands(*args):
    out_args = []

    for arg in args:
        if arg == "":
            continue
        elif arg[0] == "#":
            v = int(arg[1:], 0)

            if v < 0 or v > 0xffff:
                err(ERR_INVALID_NUMERIC_OPERAND % (v))

            out_args.append({
                'type': 'imm',
                'value': v
            })
        elif arg[0] == "@":
            if arg[1:] not in labels.keys():
                err("label '%s' not found" % (arg[1:]))

            out_args.append({
                'type': 'imm',
                'value': labels[ arg[1:] ]
            })
        elif arg.startswith("[") and arg.endswith("]"):
            p = arg[1:len(arg)-1].split(",")

            if len(p) == 1:
                out_args.append({
                    'type': 'memoffs',
                    'reg': parse_reg(p[0].lower()),
                    'offs': 0
                })
            elif p[1][0] == "#":
                v = int(p[1][1:len(p[1])],0)
                if v < 0 or v > 0xffff:
                    err(ERR_INVALID_NUMERIC_OPERAND % (v))

                out_args.append({
                    'type': 'memoffs',
                    'reg': parse_reg(p[0].lower()),
                    'offs': v
                })
            else:
                out_args.append({
                    'type': 'memreg',
                    'reg': parse_reg(p[0].lower()),
                    'offs' : parse_reg(p[1].lower())
                })
        elif arg.lower() in regs:
            out_args.append({
                'type': 'reg',
                'value': regs.index(arg.lower())
            })
        elif arg in labels.keys():
            out_args.append({
                'type': 'label',
                'value': labels[arg]
            })
        else:
            err(ERR_INVALID_OPERAND_TYPE % (arg))

    return out_args

def get_quoted_val(v):
    if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
        return v[1:len(v)-1]
    else:
        err("invalid quoted literal found")


def parse_directive(line):
    (lh, rh) = line.split(" ", 1)

    if lh == ".string":
        s = eval('"""' + get_quoted_val(rh) + '"""') + "\x00"

        return {
            'bytes': s,
            'size' : len(s)
        }
    elif lh == ".incbin":
        fn = get_quoted_val(rh)

        if not os.path.isfile(fn):
            err("could not open file '%s'" % (fn))

        d = open(fn).read()

        return {
            'bytes': d,
            'size' : len(d)
        }
    elif lh == ".byte":
        nums = "".join(rh.split()).split(",")
        d = ""
        for num in nums:
            num = int(num, 0)
            if num < 0 or num > 0xff:
                err("invalid byte value 0x%x" % (num))

            d += chr(num)

        return {
            'bytes': d,
            'size' : len(d)
        }
    elif lh == ".long":
        nums = "".join(rh.split()).split(",")
        d = ""
        for num in nums:
            num = int(num, 0)
            if num < 0 or num > 0xffffffff:
                err("invalid byte value 0x%x" % (num))

            d += struct.pack("<L", num)

        return {
            'bytes': d,
            'size' : len(d)
        }
    else:
        err("invalid directive found! %s" % (lh))

def op3(a,b,c):
    return (a<<16) | (b<<8) | c

def op2(a,b):
    return (a<<16) | b

def op_stack(*args):
    if args[0]['type'] == "reg":
        return op2(args[0]['value'], 0)
    else:
        err("you fucked up arg types")

def op_shift(*args):
    if args[0]['type'] == "reg" and args[1]['type'] == "imm":
        return op2(args[0]['value'], args[1]['value'])
    else:
        err("you fucked up arg types")

def op_alu(*args):
    if args[0]['type'] == "reg" and args[1]['type'] == "reg":
        return op3(args[0]['value'], args[1]['value'], 0)
    elif args[0]['type'] == "reg" and args[1]['type'] == "imm":
        return op2(0x10 | args[0]['value'], args[1]['value'])
    else:
        err("you fucked up arg types")

def op_nul(*args):
    return 0

def op_jmp(*args):
    if args[0]['type'] != "label":
        err("you fucked up arg types")

    return args[0]['value']

def op_sc(*args):
    if args[0]['type'] != "imm":
        err("you fucked up arg types")

    return args[0]['value']

def op_mem(*args):
    if args[0]['type'] == "reg" and args[1]['type'] == "memoffs":
        return (1<<24) | op2((args[0]['value']<<4)|args[1]['reg'], args[1]['offs'])
    elif args[0]['type'] == "reg" and args[1]['type'] == "memreg":
        return op3(args[0]['value'], args[1]['reg'], args[1]['offs'])
    else:
        err("you fucked up arg types")

mnemonics = {
    "add"  : { "func" : op_alu, "num_ops" : 2, "opcode": 0xA0 },
    "sub"  : { "func" : op_alu, "num_ops" : 2, "opcode": 0xA1 },
    "xor"  : { "func" : op_alu, "num_ops" : 2, "opcode": 0xA2 },
    "mov"  : { "func" : op_alu, "num_ops" : 2, "opcode": 0xA3 },
    "cmp"  : { "func" : op_alu, "num_ops" : 2, "opcode": 0xB0 },
    "beq"  : { "func" : op_jmp, "num_ops" : 1, "opcode": 0xC0 },
    "bne"  : { "func" : op_jmp, "num_ops" : 1, "opcode": 0xC1 },
    "jmp"  : { "func" : op_jmp, "num_ops" : 1, "opcode": 0xC2 },
    "call" : { "func" : op_jmp, "num_ops" : 1, "opcode": 0xC3 },
    "ret"  : { "func" : op_nul, "num_ops" : 0, "opcode": 0xD0 },
    "sc"   : { "func" : op_sc,  "num_ops" : 1, "opcode": 0xD1 },
    "ldr"  : { "func" : op_mem, "num_ops" : 2, "opcode": 0xE0 },
    "str"  : { "func" : op_mem, "num_ops" : 2, "opcode": 0xE2 },
    "ldrh" : { "func" : op_mem, "num_ops" : 2, "opcode": 0xE4 },
    "strh" : { "func" : op_mem, "num_ops" : 2, "opcode": 0xE6 },
    "ldrb" : { "func" : op_mem, "num_ops" : 2, "opcode": 0xE8 },
    "strb" : { "func" : op_mem, "num_ops" : 2, "opcode": 0xEA },
    "lsl"  : { "func" : op_shift, "num_ops" : 2, "opcode": 0xF0 },
    "lsr"  : { "func" : op_shift, "num_ops" : 2, "opcode": 0xF1 },
    "push" : { "func" : op_stack, "num_ops" : 1, "opcode": 0xF2 },
    "pop"  : { "func" : op_stack, "num_ops" : 1, "opcode": 0xf3 },
    "exit" : { "func" : op_nul, "num_ops" : 0, "opcode": 0xFF }
}

if len(sys.argv) == 4:
    base_addr = int(sys.argv[3], 0)
else:
    base_addr = 0

pc = base_addr

for line in open(sys.argv[1]).readlines():
    line = line.rstrip().lstrip()

    if line == "" or line.startswith("#"):
        continue

    # label?
    if line.endswith(":"):
        p = line.split(":")

        labels[ p[0] ] = pc
    elif line.startswith("."):
        pc = pc + parse_directive(line)['size']
    else:
        pc = pc + 4


pc = base_addr
o = ""

for line in open(sys.argv[1]).readlines():
    line_cnt = line_cnt+1
    line = line.rstrip().lstrip()

    # skip empty lines, labels and comments
    if line == "" or line.endswith(":") or line.startswith("#"):
        continue
    elif line.startswith("."):
        d = parse_directive(line)
        o += d['bytes']
        pc = pc + d['size']

        continue

    tmp = " ".join(line.split()).split(" ", 1)

    if len(tmp) == 1:
        mnemonic = tmp[0]
        operands = ""
    else:
        mnemonic = tmp[0]
        operands = tmp[1]

    operands = parse_operands(*operands.split(", "))
    mnemonic = mnemonic.lower()

    if mnemonic not in mnemonics.keys():
        err("invalid mnemonic: %s" % (mnemonic))

    insn = mnemonic
    mnemonic = mnemonics[mnemonic]

    if len(operands) != mnemonic['num_ops']:
        err(ERR_INVALID_ARGS % (len(operands), insn))

    opcode = (mnemonic['opcode'] << 24) | mnemonic['func'](*operands)

    o += struct.pack("<L", opcode)

    pc = pc + 4

fh = open(sys.argv[2], "wb")
fh.write(o)
fh.close()
