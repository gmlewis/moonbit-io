#!/bin/bash -ex
moon update && rm -rf target
moon fmt && moon info
moon test -j 12 --target all
