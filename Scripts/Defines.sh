#!/bin/bash

BUILD_PATH=../Build
SOURCE_PATH=..

CONFIGURATION=Debug
GENERATOR=
TOOLS=OFF
NINJA=false
XCODE=false

for Var in "$@"
do
    Var=$(echo $Var | tr '[:upper:]' '[:lower:]')
    case ${Var} in
        ninja) GENERATOR=Ninja NINJA=true ;;
        release) CONFIGURATION=Release ;;
        tools) TOOLS=ON ;;
        xcode) XCODE=true ;;
        *) break
    esac
done
