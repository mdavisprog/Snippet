set(TARGET Snippet)

set(
	SOURCE
	Main.cpp
)

add_subdirectory(Lua)

add_library(
	${TARGET}
	SHARED
	${SOURCE}
)

if(UNIX)
	target_compile_options(
		${TARGET}
		PUBLIC "-fPIC"
	)
endif()

target_link_libraries(
	${TARGET}
	Lua
)

target_include_directories(
	${TARGET}
	PUBLIC ${LUA_HEADERS}
)

set_target_properties(
	${TARGET}
	PROPERTIES
	LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIRECTORY}/${TARGET}/${PLATFORM}/${ARCH}
	RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIRECTORY}/${TARGET}/${PLATFORM}/${ARCH}
)
