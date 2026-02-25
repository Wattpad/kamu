#!/bin/bash

echo "Branch: $TRAVIS_BRANCH. PR: $TRAVIS_PULL_REQUEST"
if [ "$TRAVIS_BRANCH $TRAVIS_PULL_REQUEST" == "master false" ]; then

  pip install --user awscli
  export PATH=$PATH:$HOME/.local/bin
  eval $(aws ecr get-login --no-include-email --region us-east-1)

  export GIT_REVISION=$(git rev-parse HEAD)
  export REPO="723255503624.dkr.ecr.us-east-1.amazonaws.com/kamu"

  timestamp=$(date +%s)
  GIT_SHORT_HASH=$(git rev-parse --short HEAD)
  
  docker tag kamu:base kamu:$GIT_REVISION
  docker tag kamu:$GIT_REVISION $REPO:$GIT_REVISION-${timestamp}
  docker tag kamu:$GIT_REVISION $REPO:latest
  docker tag kamu:$GIT_REVISION $REPO:main-${timestamp}-${GIT_SHORT_HASH}
  
  docker push $REPO:$GIT_REVISION-${timestamp}
  docker push $REPO:latest
  docker push $REPO:main-${timestamp}-${GIT_SHORT_HASH}
fi
