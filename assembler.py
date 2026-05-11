 #!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

MEM_WORDS = 4096   # 4 KB / 4 bytes
WORD_BITS = 32

OPCODE = {
    "NOP":  "00000",
    "HLT":  "00001",
    "SETC": "00010",
    "INC":  "00100",
    "OUT":  "00101",
    "IN":   "00110",
    "NOT":  "00111",
    "SWAP": "01000",
    "ADD":  "01001",
    "MOV":  "01011",
    "IADD": "01100",
    "SUB":  "01110",
    "AND":  "01111",
    "PUSH": "10001",
    "POP":  "10010",
    "LDD":  "10100",
    "STD":  "10101",
    "LDM":  "10111",
    "JC":   "11000",
    "JMP":  "11001",
    "JZ":   "11010",
    "JN":   "11011",
    "INT":  "11100",
    "RTI":  "11101",
    "CALL": "11110",
    "RET":  "11111",
}


def reg(tok: str) -> str:
    m = re.fullmatch(r"[Rr]([0-7])", tok)
    if not m:
        raise ValueError(f"invalid register: {tok!r}")
    return format(int(m.group(1)), "03b")


def imm16(tok: str) -> str:
    v = int(tok, 16) & 0xFFFF
    return format(v, "016b")


def imm16_lenient(tok: str, ctx: str) -> str:
    """Like imm16 but if the token looks like a register, warn and use 0.
    Some test programs contain dead code with a register where an immediate
    should be (e.g. `IADD R1, R2, R3` after RTI). Accept it so the rest of
    the program still assembles."""
    if re.fullmatch(r"[Rr][0-7]", tok):
        print(f"warning: {ctx}: register {tok} used as immediate, treating as 0",
              file=sys.stderr)
        return "0" * 16
    return imm16(tok)


def parse_mem_operand(tok: str) -> tuple[str, str]:
    """Parse `offset(Rn)` -> (imm16_bits, reg_bits)."""
    m = re.fullmatch(r"([0-9A-Fa-f]+)\(\s*([Rr][0-7])\s*\)", tok)
    if not m:
        raise ValueError(f"invalid memory operand: {tok!r}")
    return imm16(m.group(1)), reg(m.group(2))


def split_operands(rest: str) -> list[str]:
    if not rest.strip():
        return []
    return [t.strip() for t in rest.split(",")]


def encode(line: str) -> str:
    """Encode one instruction line into a 32-bit binary string."""
    parts = line.split(None, 1)
    mnem = parts[0].upper()
    rest = parts[1] if len(parts) > 1 else ""
    ops = split_operands(rest)

    if mnem not in OPCODE:
        raise ValueError(f"unknown mnemonic: {mnem}")

    op = OPCODE[mnem]
    f1 = f2 = f3 = "000"
    imm = "0" * 16

    if mnem in ("NOP", "HLT", "SETC", "RET", "RTI"):
        if ops:
            raise ValueError(f"{mnem} takes no operands")

    elif mnem == "NOT":
        rd = reg(ops[0])
        f1, f2 = rd, rd

    elif mnem == "INC":
        rd = reg(ops[0])
        f1, f2 = rd, rd
        imm = format(1, "016b")

    elif mnem == "OUT":
        rs = reg(ops[0])
        f1, f2 = rs, rs                 # override: Rdst slot + Rsrc1 = Rdst

    elif mnem == "IN":
        f1 = reg(ops[0])

    elif mnem == "MOV":
        # MOV Rdst, Rsrc
        f1 = reg(ops[0])
        f3 = reg(ops[1])

    elif mnem == "SWAP":
        # SWAP Rdst, Rsrc   (override: Rdst | Rsrc1=Rsrc | Rsrc2=Rdst)
        rd = reg(ops[0])
        rs = reg(ops[1])
        f1, f2, f3 = rd, rs, rd

    elif mnem in ("ADD", "SUB", "AND"):
        f1 = reg(ops[0])
        f2 = reg(ops[1])
        f3 = reg(ops[2])

    elif mnem == "IADD":
        f1 = reg(ops[0])
        f2 = reg(ops[1])
        imm = imm16_lenient(ops[2], f"IADD {ops[0]},{ops[1]},{ops[2]}")

    elif mnem == "LDM":
        f1 = reg(ops[0])
        imm = imm16(ops[1])

    elif mnem == "LDD":
        # LDD Rdst, offset(Rsrc)
        f1 = reg(ops[0])
        imm, f2 = parse_mem_operand(ops[1])

    elif mnem == "STD":
        # STD Rsrc1, offset(Rsrc2)   -> f1=000, f2=Rsrc2, f3=Rsrc1
        rs1 = reg(ops[0])
        imm, rs2 = parse_mem_operand(ops[1])
        f2, f3 = rs2, rs1

    elif mnem in ("JZ", "JN", "JC", "JMP", "CALL", "INT"):
        imm = imm16(ops[0])

    elif mnem == "PUSH":
        # CSV: 000, 000, Rdst (positional). source register at f3.
        f3 = reg(ops[0])

    elif mnem == "POP":
        f1 = reg(ops[0])

    else:
        raise AssertionError("unreachable")

    bits = op + f1 + f2 + f3 + imm + "00"
    assert len(bits) == WORD_BITS, f"{mnem}: produced {len(bits)} bits"
    return bits


def is_raw_hex(line: str) -> bool:
    return bool(re.fullmatch(r"[0-9A-Fa-f]+", line))


def raw_word(line: str) -> str:
    v = int(line, 16) & 0xFFFFFFFF
    return format(v, "032b")


def assemble(src_path: Path) -> list[str]:
    mem = ["0" * WORD_BITS] * MEM_WORDS
    pc = 0

    with src_path.open("r", encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            # strip comments (# to end of line) and whitespace
            line = raw.split("#", 1)[0].strip()
            if not line:
                continue

            # .ORG directive
            if line.upper().startswith(".ORG"):
                arg = line[4:].strip()
                if not arg:
                    raise SyntaxError(f"{src_path}:{lineno}: .ORG missing address")
                pc = int(arg, 16)
                if pc < 0 or pc >= MEM_WORDS:
                    raise ValueError(
                        f"{src_path}:{lineno}: .ORG {arg} out of range (0..{MEM_WORDS-1:X})"
                    )
                continue

            try:
                if is_raw_hex(line):
                    word = raw_word(line)
                else:
                    word = encode(line)
            except Exception as e:
                raise SyntaxError(f"{src_path}:{lineno}: {e}") from None

            if pc >= MEM_WORDS:
                raise ValueError(f"{src_path}:{lineno}: program exceeds memory")

            mem[pc] = word
            pc += 1

    return mem


def write_mem(mem: list[str], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="\n") as fh:
        for w in mem:
            fh.write(w + "\n")


def assemble_file(src: Path, out: Path | None = None) -> Path:
    if out is None:
        out = src.with_suffix(".mem")
    mem = assemble(src)
    write_mem(mem, out)
    return out


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Assembler for the 6-stage RISC pipeline.")
    p.add_argument("input", nargs="?", help="input .asm file (omit with --all)")
    p.add_argument("-o", "--output", help="output .mem file")
    p.add_argument("--all", action="store_true",
                   help="assemble every .asm under programs/")
    p.add_argument("--programs-dir", default="programs",
                   help="directory holding .asm files (default: programs)")
    p.add_argument("--out-dir", default=None,
                   help="output directory (default: alongside source)")
    args = p.parse_args(argv)

    if args.all:
        root = Path(args.programs_dir)
        if not root.is_dir():
            print(f"error: {root} is not a directory", file=sys.stderr)
            return 2
        out_dir = Path(args.out_dir) if args.out_dir else None
        sources = sorted(root.glob("*.asm"))
        if not sources:
            print(f"no .asm files in {root}", file=sys.stderr)
            return 2
        fails = 0
        for src in sources:
            target = (out_dir / (src.stem + ".mem")) if out_dir else src.with_suffix(".mem")
            try:
                assemble_file(src, target)
                print(f"OK  {src.name} -> {target}")
            except Exception as e:
                fails += 1
                print(f"FAIL {src.name}: {e}", file=sys.stderr)
        return 1 if fails else 0

    if not args.input:
        p.print_usage(sys.stderr)
        return 2
    src = Path(args.input)
    out = Path(args.output) if args.output else None
    target = assemble_file(src, out)
    print(f"OK  {src} -> {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
