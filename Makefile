ODIN ?= $(shell which odin)
ODIN_FLAGS := -show-timings -o:speed -debug

WORKDIR := $(shell pwd)
ODIN_DIR := $(WORKDIR)/glint
BIN_DIR := $(WORKDIR)/bin
TARGET := $(BIN_DIR)/glint
SOKOL := $(WORKDIR)/vendor/sokol-odin/sokol

ODIN_FLAGS += -out:$(TARGET) -collection:sokol=vendor/sokol-odin/sokol

.PHONY: all clean run prepare $(TARGET) 

all: prepare $(TARGET)

$(TARGET): $(ODIN_DIR) $(SOKOL)
	@$(MAKE) -f sokol.mk WORKDIR=$(WORKDIR)
	$(ODIN) build $(ODIN_DIR) $(ODIN_FLAGS)

prepare:
	@mkdir -p $(BIN_DIR)

clean:
	@$(MAKE) -f sokol.mk clean WORKDIR=$(WORKDIR)
	rm -rf $(BIN_DIR)

run: prepare $(TARGET)
	@$(TARGET) $(ARGS)
