cmake_minimum_required(VERSION 3.15)
project(gpu_pyodide LANGUAGES CXX)

# scikit-build-core provides SKBUILD_PYTHON_PATH with correct Python
find_package(Python 3.10 COMPONENTS Interpreter Development.Module REQUIRED)
find_package(nanobind CONFIG REQUIRED)

nanobind_add_module(_pyodide FREE_THREADED src/_pyodide.cpp)

install(TARGETS _pyodide DESTINATION gpu/pyodide)

# Generate stubs for type checking support
# Skip for cross-compilation (Pyodide) - stubs generated separately via inject_stub.py
if(NOT CMAKE_CROSSCOMPILING)
    # Delete any existing stub to ensure fresh generation
    file(REMOVE ${CMAKE_CURRENT_SOURCE_DIR}/src/gpu/pyodide/_pyodide.pyi)
    nanobind_add_stub(
        _pyodide_stub
        MODULE _pyodide
        OUTPUT _pyodide.pyi
        PYTHON_PATH $<TARGET_FILE_DIR:_pyodide>
        DEPENDS _pyodide
    )
    # Install stub alongside the compiled module
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/_pyodide.pyi DESTINATION gpu/pyodide)
    # Also copy stub to source directory for IDE support during development
    add_custom_command(
        TARGET _pyodide_stub POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_CURRENT_BINARY_DIR}/_pyodide.pyi
            ${CMAKE_CURRENT_SOURCE_DIR}/src/gpu/pyodide/_pyodide.pyi
        COMMENT "Copying stub to source directory for IDE support"
    )
endif()
