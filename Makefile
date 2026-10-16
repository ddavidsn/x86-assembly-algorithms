NASM := nasm
CC := gcc
ASMFLAGS := -f elf64 -g
CFLAGS := -std=c11 -Wall -Wextra -O2
LDFLAGS := -no-pie

.PHONY: all demo check clean

all: build/vector_demo build/rpn_demo build/printf_demo build/langford_demo build/bonus_demo

build:
	mkdir -p build

build/my_vector.o: src/my_vector.asm | build
	$(NASM) $(ASMFLAGS) $< -o $@
build/reverse_polish_notation.o: src/reverse_polish_notation.asm | build
	$(NASM) $(ASMFLAGS) $< -o $@
build/my_printf.o: src/my_printf.asm | build
	$(NASM) $(ASMFLAGS) $< -o $@
build/langford.o: src/langford.asm | build
	$(NASM) $(ASMFLAGS) $< -o $@
build/bonus.o: src/bonus.asm | build
	$(NASM) $(ASMFLAGS) $< -o $@

build/vector_demo: examples/vector_demo.c build/my_vector.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/rpn_demo: examples/rpn_demo.c build/reverse_polish_notation.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/printf_demo: examples/printf_demo.c build/my_printf.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/langford_demo: examples/langford_demo.c build/langford.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/bonus_demo: examples/bonus_demo.c build/bonus.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

demo: all
	./build/vector_demo
	./build/rpn_demo < examples/rpn.in
	./build/printf_demo
	./build/langford_demo
	./build/bonus_demo

check: all
	./build/rpn_demo < examples/rpn.in | diff -u examples/rpn.expected.txt -
	./build/vector_demo > /dev/null
	./build/langford_demo > /dev/null

clean:
	rm -rf build
