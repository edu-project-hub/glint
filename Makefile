ODIN?=$(shell which odin)
ODIN_FLAGS:= -show-timings -o:none -debug

WORKDIR:=$(shell pwd)
ODIN_DIR:=$(WORKDIR)/glint
BIN_DIR:=$(WORKDIR)/bin

TARGET:=$(BIN_DIR)/glint
ODIN_FLAGS+= -out:$(TARGET)

.PHONY: all clean run prepare

all: prepare $(TARGET)

$(TARGET): $(ODIN_DIR)
	$(ODIN) build $(ODIN_DIR) $(ODIN_FLAGS)
	
prepare:
	@mkdir -p $(BIN_DIR)

clean:
	rm -r $(BIN_DIR)
	
run: $(TARGET)
