#!/usr/bin/python

import random
import os
from functools import reduce

def bin(x, width):
    if x < 0: x = (~x) + 1
    return ''.join([(x & (1 << i)) and '1' or '0' for i in range(width-1, -1, -1)])

def sra(a, b):
    if b == 0:
        return a
    elif a & (1<<31):
        out = (a >> b) | reduce(lambda a,b: a|b, [1 << x for x in range(31, 31-b, -1)])
        return out
    else:
        out = a >> b
        return out

def sext(a):
    if not a & (1<<15):
        return a
    else:
        return 0xffff0000 | (abs(a)&0xffff)

def bwnot(a):
    return reduce(lambda a,b: a|b, [([1,0][a>>x & 1]) << x for x in range(0,32)])

def flipsign(a):
    if a < 0:
        return bwnot(abs(a)) + 1
    elif a & (1<<31):
        return -(bwnot(a) + 1)
    else:
        return a

def comp(a,b):
    a = flipsign(a)
    b = flipsign(b)
    return a < b

def sub(a,b):
    res = a-b 
    if res < 0:
        return bwnot(abs(res)) + 1
    else:
        return res

# tuple contains (opcode/funct bits, function, limit for a, limit for b)
opcodes = \
{ 
    "LUI":      ("0110111", lambda a,b: b, lambda a: a, lambda b: b),
    "AUIPC":    ("0010111", lambda a,b: a+b, lambda a: a, lambda b: b),
    "JAL":      ("1101111", lambda a,b: a+b, lambda a: a, lambda b: b),
    "JALR":     ("1100111", lambda a,b: a+b, lambda a: a, lambda b: b),
    "BRANCH":   ("1100011", lambda a,b: a+b, lambda a: a, lambda b: b),
    "LOAD":     ("0000011", lambda a,b: a+b, lambda a: a, lambda b: b),
    "STORE":    ("0100011", lambda a,b: a+b, lambda a: a, lambda b: b),
    "ITYPE":    ("0010011", lambda a,b: 0, lambda a: a, lambda b: b),
    "RTYPE":    ("0110011", lambda a,b: 0, lambda a: a, lambda b: b),
}

functs_itype = \
{
    "ADDI":    ("000", "0", lambda a,b: a+b, lambda a: a, lambda b: sext(b&0x0fff)),
    "SLTI":    ("010", "0", lambda a,b: (lambda:0, lambda:1)[comp(a,b)](), lambda a: a, lambda b: sext(b&0x0fff)),
    "SLTIU":   ("011", "0", lambda a,b: (lambda:0, lambda:1)[a < b](), lambda a: a, lambda b: sext(b&0x0fff)),
    "XORI":    ("100", "0", lambda a,b: a^b, lambda a: a, lambda b: sext(b&0x0fff)),
    "ORI":     ("110", "0", lambda a,b: a|b, lambda a: a, lambda b: sext(b&0x0fff)),
    "ANDI":    ("111", "0", lambda a,b: a&b, lambda a: a, lambda b: sext(b&0x0fff)),

    "SLLI":    ("001", "0", lambda a,b: a<<b, lambda a: a, lambda b: b&0x1f),
    "SRLI":    ("101", "0", lambda a,b: a>>b, lambda a: a, lambda b: b&0x1f),
    "SRAI":    ("101", "1", lambda a,b: sra(a,b), lambda a: a, lambda b: b&0x1f),
}

functs_rtype = \
{
    "ADD":     ("000", "0", lambda a,b: a+b, lambda a: a, lambda b: b),
}

random.seed(os.urandom(32))
file = open('testvectors.input', 'w')

def gen_vector(op, f, a, b, opcode, funct3, funct7):
    A = a(random.randint(0, 0xffffffff))
    B = b(random.randint(0, 0xffffffff))
    REFout = f(A,B)
    return ''.join([opcode, funct3, funct7, bin(A, 32), bin(B, 32), bin(REFout, 32)])

loops = 5

for i in range(loops):
    for opcode, tup in opcodes.items():
        oc, f, a, b = tup
        if opcode == "RTYPE":
            for funct, tup in functs_rtype.items():
                fct, add_rshift_type, f, a, b = tup
                file.write(gen_vector(funct, f, a, b, oc, fct, add_rshift_type) + '\n')
        elif opcode == "ITYPE":
            for funct, tup in functs_itype.items():
                fct, add_rshift_type, f, a, b = tup
                file.write(gen_vector(funct, f, a, b, oc, fct, add_rshift_type) + '\n')
        else:
            fct = bin(random.randint(0, 0x7), 3)
            add_rshift_type = bin(random.randint(0, 0x1), 1)
            file.write(gen_vector(fct, f, a, b, oc, fct, add_rshift_type) + '\n')

