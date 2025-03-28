#!/bin/sh -e

BIN_DIR=./bin
TARGET=$BIN_DIR/glint

mkdir -p $BIN_DIR
odin build ./glint -out:$TARGET -collection:sokol=vendor/sokol-odin/sokol
