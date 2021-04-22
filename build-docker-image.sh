#!/bin/bash

IMAGE_NAME="cmaq"
TIMESTAMP=`date "+%Y%m%d%H%M"`
# VERSION="0.0.1"

docker build --no-cache -t $IMAGE_NAME:$TIMESTAMP -t $IMAGE_NAME:latest \
    -t helxplatform/$IMAGE_NAME:$TIMESTAMP -t helxplatform/$IMAGE_NAME:latest .
#     -t helxplatform/$IMAGE_NAME:$VERSION -t helxplatform/$IMAGE_NAME:latest .
