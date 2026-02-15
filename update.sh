#!/bin/bash -ex
moon update && rm -rf _build .mooncakes
moon fmt && moon info
moon test -j 12 --target all
