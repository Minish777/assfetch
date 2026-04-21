# assfetch build configuration
# Author: Rootly

AS      = nasm
ASFLAGS = -f elf64
LD      = ld
# Strip all symbols to minimize binary size
LDFLAGS = -s
TARGET  = assfetch
SRC     = fetch.asm
OBJ     = fetch.o

.PHONY: all clean install

# Default target
all: $(TARGET)

# Link object files into executable
$(TARGET): $(OBJ)
	$(LD) $(LDFLAGS) $(OBJ) -o $(TARGET)

# Assemble source files
$(OBJ): $(SRC)
	$(AS) $(ASFLAGS) $(SRC) -o $(OBJ)

# Remove build artifacts
clean:
	rm -f $(OBJ) $(TARGET)

# Copy binary to system path
install: $(TARGET)
	@echo "Installing $(TARGET) to /usr/local/bin..."
	sudo cp $(TARGET) /usr/local/bin/
	sudo chmod 755 /usr/local/bin/$(TARGET)
