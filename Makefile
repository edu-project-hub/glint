ODIN ?= $(shell which odin)
ODIN_FLAGS := -show-timings -o:none -debug

WORKDIR := $(shell pwd)
ODIN_DIR := $(WORKDIR)/glint
BIN_DIR := $(WORKDIR)/bin
TARGET := $(BIN_DIR)/glint

ODIN_FLAGS += -out:$(TARGET) -collection:sokol=vendor/sokol-odin/sokol

# In order to detect file changes we need to tell make to get all files 
SRC_FILES := $(shell find $(ODIN_DIR) -name '*.odin') 
VENDOR_FILES := $(shell find vendor/sokol-odin/sokol -name '*.odin')
ALL_SOURCES := $(SRC_FILES) $(VENDOR_FILES)

.PHONY: all clean run prepare

all: prepare $(TARGET)

$(TARGET): $(ALL_SOURCES)
	$(ODIN) build $(ODIN_DIR) $(ODIN_FLAGS)

prepare:
	@mkdir -p $(BIN_DIR)

clean:
	rm -rf $(BIN_DIR)

run: prepare $(TARGET)
	@$(TARGET) $(ARGS)
