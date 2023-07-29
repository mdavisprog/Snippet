set(TARGET CLIENT)

add_executable(${TARGET} Main.cpp)

set_target_properties(
    ${TARGET}
    PROPERTIES
    RUNTIME_OUTPUT_NAME Snippet
)
