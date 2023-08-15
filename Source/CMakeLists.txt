set(CMAKE_CXX_STANDARD 17)

set(CMAKE_COMPILE_WARNING_AS_ERROR ON)
if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -pedantic -Werror)
endif()

add_subdirectory(Client)
add_subdirectory(Server)
