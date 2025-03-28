#!/bin/sh -e

git submodule update --init --recursive
pushd ./vendor/sokol-odin/sokol
./build_clibs_linux.sh
popd
