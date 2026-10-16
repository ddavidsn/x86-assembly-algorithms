# x86-64 Assembly: Low-Level Programming & Algorithms

Five university programming challenges implemented in **x86-64 NASM Assembly**: dynamic arrays, postfix expression evaluation, formatted output, recursive backtracking, and low-level utilities.

> **Project context:** My implementations for a university computer-organization / low-level programming assignment. The original assignment specification, grading checker, reference data, and Git history are not redistributed here. Small C drivers in `examples/` were created for this portfolio so the Assembly routines can be exercised independently.

## Implemented modules

| Module | Main functionality | Key concepts |
| --- | --- | --- |
| `src/my_vector.asm` | Resizable integer vector (push, pop, get, set, print, free) | Heap allocation, `malloc`/`realloc`/`free`, pointer arithmetic |
| `src/reverse_polish_notation.asm` | Evaluates postfix integer expressions from standard input | Stack management, signed 64-bit arithmetic |
| `src/my_printf.asm` | Minimal variadic formatter supporting `%s`, `%c`, `%lu` | System V AMD64 calling convention, register and stack arguments |
| `src/langford.asm` | Validates and generates Langford sequences | Backtracking, recursion, dynamic result storage |
| `src/bonus.asm` | Character transforms, bit-based classification, flattened-matrix column maxima | Bit manipulation, strings, array indexing |

The Assembly routines are the original assignment implementations; the portfolio contains no university-provided checker or private grading scripts. The project is intended as a **learning and demonstration exercise**, not as a production-ready library.

## Requirements

- **Linux x86-64** (or Windows with **WSL2** running a Linux distribution)
- [NASM](https://www.nasm.us/) assembler
- GCC and GNU Make

The routines use the **System V AMD64 ABI** and are linked to small C driver programs. They are not designed for the native Windows x64 calling convention.

For Ubuntu / Debian inside Linux or WSL, install the build dependencies with:

```bash
sudo apt update
sudo apt install nasm gcc make
```

## Build and run

From the repository root:

```bash
make all      # assemble and link five demonstrations
make demo     # run all five demonstration programs
make check    # check the postfix example and basic vector/Langford assertions
make clean    # remove compiled files
```

To run the postfix notation example separately:

```bash
./build/rpn_demo < examples/rpn.in
```

Expected output:

```text
14
```

The original code uses a bounded buffer for the RPN token stack; examples should not be interpreted as proof of correct handling of arbitrarily large inputs.

## Source layout

```text
src/
  my_vector.asm
  reverse_polish_notation.asm
  my_printf.asm
  langford.asm
  bonus.asm
examples/
  vector_demo.c
  rpn_demo.c
  printf_demo.c
  langford_demo.c
  bonus_demo.c
  rpn.in
  rpn.expected.txt
Makefile
README.md
.gitignore
```

## Verification and limitations

The uploaded university project archive contained saved output files for **35 assignment cases**, and all 35 matched their corresponding reference outputs (5 vector, 5 RPN, 5 printf, 10 Langford, 10 bonus). Those were **previously saved results**, not fresh test runs. A fresh NASM build and a memory-safety audit have **not** been performed for this portfolio version; verify with `make check` and additional testing in your Linux/WSL environment.

The code implements the assignment's defined input ranges and supported format specifiers; it is not a drop-in replacement for the C standard library.

## Attribution

Assembly source: university coursework implementation. Original course scaffolding and assignment specification belong to their respective authors and are excluded from this repository. The standalone C demo programs and this README were added to present the work as a portfolio project.
