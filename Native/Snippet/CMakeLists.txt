set(TARGET Snippet)

set(
	SOURCE
	Main.cpp
	SnippetStub.cpp
)

add_subdirectory(Lua)

add_library(
	${TARGET}
	SHARED
	${SOURCE}
)

target_compile_options(
	${TARGET}
	PUBLIC "-fPIC"
)

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
