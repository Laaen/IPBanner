#!/bin/bash

./test.sh
cd ..
echo "Building"
crystal build --release src/ip_banner.cr