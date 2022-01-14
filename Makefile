# Makefile - GNU Makefile

SOURCES=mfm-150.asm strings.inc

IMAGES=mfm-150.bin

all: $(SOURCES) $(IMAGES)

mfm-150.bin: $(SOURCES)
	nasm -O9 -f bin -o mfm-150.bin -l mfm-150.lst mfm-150.asm

clean:
	rm -f mfm-150.bin

