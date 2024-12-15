BUILDER="fasm"
BUILD_DIR="build"

all: run

dir:
	@mkdir -p $(BUILD_DIR)

clean:
	@rm -rf $(BUILD_DIR)

build: dir
	@$(BUILDER) calc.s
	@mv calc $(BUILD_DIR)/

run: build
	@$(BUILD_DIR)/calc

# Tiny and fast Linux ELF executable debugger
# http://fdbg.x86asm.net/ 
debug: build
	@./fdbg/fdbg $(BUILD_DIR)/calc

# Shortcuts
dbg: debug

.PHONY: dir clean build run debug