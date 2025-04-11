ODIN ?= odin
PYTHON ?= python3

WORKDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ODIN_DIR := $(WORKDIR)/glint
BIN_DIR := $(WORKDIR)/bin
TARGET := $(BIN_DIR)/glint
TOOLS_DIR := $(WORKDIR)/tools
SOKOL := $(WORKDIR)/vendor/sokol-odin/sokol

ODIN_FLAGS := -show-timings -o:none -debug -out:$(TARGET) 
ODIN_CHECK := -collection:sokol=$(SOKOL) -collection:glint=$(ODIN_DIR)
ODIN_FLAGS += $(ODIN_CHECK)

.PHONY: all clean run prepare $(TARGET) generate_shaders check

all: prepare $(TARGET)

$(SOKOL):
	sh $(TOOLS_DIR)/init.sh

$(TARGET): $(ODIN_DIR) | $(SOKOL)
	$(PYTHON) $(TOOLS_DIR)/sokol.py $(WORKDIR)
	$(ODIN) build $(ODIN_DIR) $(ODIN_FLAGS)

check:
	$(ODIN) check $(ODIN_DIR) $(ODIN_CHECK)

prepare:
	@mkdir -p $(BIN_DIR)

clean:
	rm -rf $(BIN_DIR)

run: prepare $(TARGET)
	@$(TARGET) $(ARGS)

generate_shaders:
	$(PYTHON) $(TOOLS_DIR)/generate_shaders.py $(WORKDIR)
