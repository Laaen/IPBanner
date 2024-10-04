#!/bin/bash

./test.sh
cd ..
echo "Building"
crystal build --release -Dpreview_mt src/ip_banner.cr