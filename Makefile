APP      := asmcalc
SRC_DIR  := src
BUILD_DIR := build

NASM     := nasm
LD       := ld
STRIP    := strip

SOURCES  := $(wildcard $(SRC_DIR)/*.asm)
OBJECTS  := $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/%.o,$(SOURCES))
TARGET   := $(BUILD_DIR)/$(APP)
STRIPPED_TARGET := $(BUILD_DIR)/$(APP)-stripped

NASMFLAGS := -f elf64 -g -F dwarf
LDFLAGS   := -dynamic-linker /lib64/ld-linux-x86-64.so.2
LDLIBS    := -lX11 -lXft -lc -lm

.PHONY: all build stripped run debug clean

all: $(TARGET)

build: all

stripped: $(STRIPPED_TARGET)

$(STRIPPED_TARGET): $(TARGET)
	cp $(TARGET) $@
	$(STRIP) --strip-all $@

$(TARGET): $(OBJECTS)
	@test -n "$^" || { echo "No NASM source files found in $(SRC_DIR)/" >&2; exit 1; }
	@mkdir -p $(BUILD_DIR)
	$(LD) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm
	@mkdir -p $(BUILD_DIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

debug: $(TARGET)
	gdb ./$(TARGET)

clean:
	rm -rf $(BUILD_DIR)
