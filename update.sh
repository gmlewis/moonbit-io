#!/bin/bash -ex
moon update && moon install && rm -rf target
moon fmt
# Currently, "js" is the only target where tests pass:
moon test --target js
