#!/bin/bash

cd ..
echo 'Getting shards'
shards install
echo 'Running tests'
sudo crystal spec -D test