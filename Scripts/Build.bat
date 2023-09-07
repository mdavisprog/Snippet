@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

PUSHD "%~dp0"

IF "%OctaneGUI_DIR%" == "" (
    ECHO OctaneGUI_DIR environment variable not defined! Please provide a path to the OctaneGUI installation through the OctaneGUI_DIR variable!
    EXIT -1
)

CALL Defines.bat %*

CALL VCVars.bat %*
IF NOT EXIST "%VCVARS%" (
    ECHO VCVars batch file "%VCVARS%" does not exist!. A valid Visual Studio installation was not found. Please verify a valid Visual Studio install exists before attempting to call the VCVars batch file.
    EXIT -1
)
CALL "%VCVARS%"

SET SDL2_MODULE_PATH=%SDL2_DIR:\=/%
SET SDL2_MODULE_PATH=%SDL2_MODULE_PATH%/cmake

SET CMAKE_OPTIONS=-S %SOURCE_PATH% -B %BUILD_PATH% -DCMAKE_BUILD_TYPE=%CONFIGURATION% -DTOOLS=%TOOLS% -DWINDOWING=SDL2 -DRENDERING=OpenGL
SET CMAKE_OPTIONS=%CMAKE_OPTIONS% -DOctaneGUI_DIR=%OctaneGUI_DIR% -DSDL2_DIR=%SDL2_DIR% -DCMAKE_MODULE_PATH=%SDL2_MODULE_PATH%

IF NOT "%GENERATOR%" == "" (
    SET CMAKE_OPTIONS=-G %GENERATOR% %CMAKE_OPTIONS%
)

cmake %CMAKE_OPTIONS%

IF "%NINJA%" == "TRUE" (
    ninja --version
    ninja -C %BUILD_PATH%
) ELSE (
    msbuild %BUILD_PATH%\Snippet.sln /p:Configuration=%CONFIGURATION%
)

POPD
ENDLOCAL
