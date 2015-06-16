#!/bin/bash

set -e
set -x

cd $(dirname $(readlink -f "$0"))

docker pull nilcons/ghc-musl-auto:ghc-musl

docker tag $(docker history nilcons/ghc-musl-auto:ghc-musl | grep Layer\ 1 | cut -d\  -f1) nilcons/ghc-musl:base
docker tag $(docker history nilcons/ghc-musl-auto:ghc-musl | grep Layer\ 2 | cut -d\  -f1) nilcons/ghc-musl:cabal
docker tag $(docker history nilcons/ghc-musl-auto:ghc-musl | grep Layer\ 3 | cut -d\  -f1) nilcons/ghc-musl:stackage
docker tag nilcons/ghc-musl-auto:ghc-musl nilcons/ghc-musl:latest

docker run -i --rm nilcons/ghc-musl:latest /bin/sh -c "ghc-pkg recache; ghc-pkg list" >../packages.txt
docker push nilcons/ghc-musl:base
docker push nilcons/ghc-musl:cabal
docker push nilcons/ghc-musl:stackage
docker push nilcons/ghc-musl:latest
