AS = nasm
ASFLAGS = -f elf64
LD = ld
TARGET = assfetch

all: $(TARGET)

$(TARGET): fetch.o
	$(LD) fetch.o -o $(TARGET)

fetch.o: fetch.asm
	$(AS) $(ASFLAGS) fetch.asm -o fetch.o

clean:
	rm -f *.o $(TARGET)

install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/$(TARGET)

uninstall:
	rm -f /usr/local/bin/$(TARGET)