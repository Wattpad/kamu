#!/bin/bash

echo "Branch: $TRAVIS_BRANCH. PR: $TRAVIS_PULL_REQUEST"
if [ "$TRAVIS_BRANCH $TRAVIS_PULL_REQUEST" == "master false" ]; then

  pip install --user awscli
  export PATH=$PATH:$HOME/.local/bin
  eval $(aws ecr get-login --region us-east-1)

  export GIT_REVISION=$(git rev-parse HEAD)
  export REPO="723255503624.dkr.ecr.us-east-1.amazonaws.com/kamu"
  docker tag kamu:base kamu:$GIT_REVISION
  docker tag kamu:$GIT_REVISION $REPO:$GIT_REVISION
  docker push $REPO:$GIT_REVISION

fi
