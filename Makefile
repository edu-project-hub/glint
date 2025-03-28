ODIN ?= $(shell which odin)
ODIN_FLAGS := -show-timings -o:none -debug

WORKDIR := $(shell pwd)
ODIN_DIR := $(WORKDIR)/glint
BIN_DIR := $(WORKDIR)/bin
TARGET := $(BIN_DIR)/glint
SOKOL := $(WORKDIR)/vendor/sokol-odin/sokol

ODIN_FLAGS += -out:$(TARGET) -collection:sokol=vendor/sokol-odin/sokol

.PHONY: all clean run prepare $(TARGET) 

all: prepare $(TARGET)

$(TARGET): $(ODIN_DIR) $(SOKOL)
	@cd $(SOKOL) && sh build_clibs_linux.sh
	$(ODIN) build $(ODIN_DIR) $(ODIN_FLAGS)

prepare:
	@mkdir -p $(BIN_DIR)

clean:
	rm -rf $(BIN_DIR)

run: prepare $(TARGET)
	@$(TARGET) $(ARGS)
