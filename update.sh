#!/bin/bash -ex
moon update && moon install && rm -rf target
moon fmt
moon test --target all
# Currently, this fails:
# moon test --target native
