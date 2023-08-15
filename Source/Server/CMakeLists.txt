set(TARGET SERVER)

set(SOURCE
    Main.cpp
)

add_executable(${TARGET} ${SOURCE})

set_target_properties(
    ${TARGET}
    PROPERTIES
    RUNTIME_OUTPUT_NAME SnippetServer
)
