CC       ?= $(shell which gcc)
AR       ?= $(shell which ar)
ARFLAGS  := rcs

WORKDIR  ?= $(shell pwd)
SOKOL    := $(WORKDIR)/vendor/sokol-odin/sokol
SRC_DIR  := $(SOKOL)/c
OUT_DIR  := $(SOKOL)/gfx
SRC      := $(SRC_DIR)/sokol_gfx.c

OBJ_DEBUG    := $(SRC:.c=_debug.o)
OBJ_RELEASE  := $(SRC:.c=_release.o)

LIB_DEBUG    := $(OUT_DIR)/sokol_gfx_linux_x64_gl_debug.a
LIB_RELEASE  := $(OUT_DIR)/sokol_gfx_linux_x64_gl_release.a

CFLAGS_DEBUG   := -pthread -c -g -DIMPL -DSOKOL_GLCORE
CFLAGS_RELEASE := -pthread -c -O2 -DNDEBUG -DIMPL -DSOKOL_GLCORE

.PHONY: all clean

all: $(LIB_RELEASE) $(LIB_DEBUG)

$(LIB_RELEASE): $(SRC)
	$(CC) $(CFLAGS_RELEASE) -o $(OBJ_RELEASE) -c $(SRC)
	$(AR) $(ARFLAGS) $@ $(OBJ_RELEASE)
	rm -f $(OBJ_RELEASE)

$(LIB_DEBUG): $(SRC)
	$(CC) $(CFLAGS_DEBUG) -o $(OBJ_DEBUG) -c $(SRC)
	$(AR) $(ARFLAGS) $@ $(OBJ_DEBUG)
	rm -f $(OBJ_DEBUG)

clean:
	rm -f $(LIB_RELEASE) $(LIB_DEBUG)
