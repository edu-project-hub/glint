ODIN ?= $(shell which odin)
PYTHON ?= $(shell which python3)
ODIN_FLAGS := -show-timings -o:none -debug

WORKDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ODIN_DIR := $(WORKDIR)/glint
BIN_DIR := $(WORKDIR)/bin
TARGET := $(BIN_DIR)/glint
TOOLS_DIR := $(WORKDIR)/tools

ODIN_FLAGS += -out:$(TARGET) -collection:sokol=vendor/sokol-odin/sokol

.PHONY: all clean run prepare $(TARGET) 

all: prepare $(TARGET)

$(TARGET): $(ODIN_DIR) $(SOKOL)
	$(PYTHON) $(TOOLS_DIR)/sokol.py $(WORKDIR)
	$(ODIN) build $(ODIN_DIR) $(ODIN_FLAGS)

prepare:
	@mkdir -p $(BIN_DIR)

clean:
	@$(MAKE) -f sokol.mk clean WORKDIR=$(WORKDIR)
	rm -rf $(BIN_DIR)

run: prepare $(TARGET)
	@$(TARGET) $(ARGS)
