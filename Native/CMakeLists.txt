cmake_minimum_required(VERSION 3.17)

project(NativeScript)

message("Currently using CMake version ${CMAKE_VERSION}")

set(CMAKE_CXX_STANDARD 11)

# Set the platform
if(APPLE)
	set(PLATFORM Mac)
elseif(WIN32)
	set(PLATFORM Windows)
else()
	set(PLATFORM Unknown)
endif()

# Check for 64-bit compiler
if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "4")
	set(ARCH x86)
else()
	set(ARCH x64)
endif()

set(GODOT_CPP ${CMAKE_CURRENT_SOURCE_DIR}/godot-cpp)
set(GODOT_HEADERS ${GODOT_CPP}/godot-headers)
set(LUA_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/Lua)
set(OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../Libraries)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/Bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/Bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIRECTORY}/${PROJECT_NAME}/${PLATFORM}/${ARCH})

if(WIN32)
	set(GODOT_LIB ${GODOT_CPP}/bin/libgodot-cpp.windows.release.64.lib)
elseif(APPLE)
	set(GODOT_LIB ${GODOT_CPP}/bin/libgodot-cpp.osx.release.64.a)
endif()

if(NOT GODOT_LIB)
	message(
		FATAL_ERROR
		"GODOT_LIB not set for current platform."
	)
endif()

if(NOT EXISTS ${GODOT_LIB})
	message(
		FATAL_ERROR
		"Godot cpp library '${GODOT_LIB}' does not exist."
	)
endif()

include_directories(
	${GODOT_CPP}/include/
	${GODOT_CPP}/include/core
	${GODOT_CPP}/include/gen
	${GODOT_HEADERS}
)

link_libraries(
	${GODOT_LIB}
)

add_subdirectory(Lua)
add_subdirectory(Snippet)
