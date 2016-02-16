#!/bin/bash

$(aws ecr get-login --region us-east-1)

export GIT_REVISION=$(git rev-parse HEAD)
export BUILD_WEEK=$(date +%V)

docker build -t kamu:$BUILD_WEEK-$GIT_REVISION .
docker tag kamu:$BUILD_WEEK-$GIT_REVISION 723255503624.dkr.ecr.us-east-1.amazonaws.com/kamu:$BUILD_WEEK-$GIT_REVISION
docker push 723255503624.dkr.ecr.us-east-1.amazonaws.com/kamu:$BUILD_WEEK-$GIT_REVISION
