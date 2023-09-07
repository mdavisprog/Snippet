#!/bin/bash

pushd "$(dirname "${BASH_SOURCE[0]}")"

source Defines.sh

if [[ -z $OctaneGUI_DIR ]] ; then
    echo "OctaneGUI_DIR environment variable not defined! Please provide a path to the OctaneGUI installation through the OctaneGUI_DIR variable!"
    exit 1;
fi

CMAKE_OPTIONS="-S $SOURCE_PATH -B $BUILD_PATH -DCMAKE_BUILD_TYPE=$CONFIGURATION -DTOOLS=$TOOLS -DWINDOWING=SDL2"
CMAKE_OPTIONS="$CMAKE_OPTIONS -DOctaneGUI_DIR=$OctaneGUI_DIR -DSDL2_DIR=$SDL2_DIR -DCMAKE_MODULE_PATH=$SDL2_DIR/cmake"

if [[ ! -z $GENERATOR ]] ; then
    CMAKE_OPTIONS="-G $GENERATOR $CMAKE_OPTIONS"
fi

cmake $CMAKE_OPTIONS

if [ "$NINJA" = true ] ; then
    NINJA_VERSION=$(ninja --version)
    echo "Using ninja version $NINJA_VERSION"
    ninja -C $BUILD_PATH
elif [ "$XCODE" = true ] ; then
    xcodebuild -configuration $CONFIGURATION -scheme ALL_BUILD -project "$BUILD_PATH/Snippet.xcodeproj"
else
    make -C $BUILD_PATH
fi

popd
