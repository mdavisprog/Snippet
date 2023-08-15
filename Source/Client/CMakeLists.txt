set(TARGET CLIENT)

find_package(OctaneGUI REQUIRED)

set(SOURCE
    Controls/ConnectionButton.cpp
    Main.cpp
)

add_executable(${TARGET} ${SOURCE})

set_target_properties(
    ${TARGET}
    PROPERTIES
    RUNTIME_OUTPUT_NAME Snippet
)

target_include_directories(
    ${TARGET}
    PRIVATE ${OctaneGUI_INCLUDE_DIRS}
)

target_link_libraries(
    ${TARGET}
    ${OctaneGUI_LIBRARIES}
)

file(COPY ${OctaneGUI_RESOURCES_DIR} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
file(COPY ${PROJECT_SOURCE_DIR}/Resources DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
