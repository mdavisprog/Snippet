@ECHO OFF

SET BUILD_PATH=..\Build
SET SOURCE_PATH=..

SET CONFIGURATION=Debug
SET GENERATOR=
SET TOOLS=OFF
SET NINJA=FALSE

:PARSE_ARGS
IF NOT "%1" == "" (
    IF /I "%1" == "Release" SET CONFIGURATION=Release
    IF /I "%1" == "Ninja" (
        SET NINJA=TRUE
        SET GENERATOR=Ninja
    )
    IF /I "%1" == "Tools" SET TOOLS=ON
    SHIFT
    GOTO :PARSE_ARGS
)
