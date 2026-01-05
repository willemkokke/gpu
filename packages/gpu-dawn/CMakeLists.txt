cmake_minimum_required(VERSION 3.15)
project(gpu_dawn LANGUAGES CXX)

# scikit-build-core provides SKBUILD_PYTHON_PATH with correct Python
find_package(Python 3.10 COMPONENTS Interpreter Development.Module REQUIRED)
find_package(nanobind CONFIG REQUIRED)

nanobind_add_module(_dawn FREE_THREADED src/_dawn.cpp)

install(TARGETS _dawn DESTINATION gpu/dawn)

# Generate stubs for type checking support
# Skip for cross-compilation (Pyodide) - stubs generated separately via inject_stub.py
if(NOT CMAKE_CROSSCOMPILING)
    # Delete any existing stub to ensure fresh generation
    file(REMOVE ${CMAKE_CURRENT_SOURCE_DIR}/src/gpu/dawn/_dawn.pyi)
    nanobind_add_stub(
        _dawn_stub
        MODULE _dawn
        OUTPUT _dawn.pyi
        PYTHON_PATH $<TARGET_FILE_DIR:_dawn>
        DEPENDS _dawn
    )
    # Install stub alongside the compiled module
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/_dawn.pyi DESTINATION gpu/dawn)
    # Also copy stub to source directory for IDE support during development
    add_custom_command(
        TARGET _dawn_stub POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_CURRENT_BINARY_DIR}/_dawn.pyi
            ${CMAKE_CURRENT_SOURCE_DIR}/src/gpu/dawn/_dawn.pyi
        COMMENT "Copying stub to source directory for IDE support"
    )
endif()
