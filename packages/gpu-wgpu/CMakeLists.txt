cmake_minimum_required(VERSION 3.15)
project(gpu_wgpu LANGUAGES CXX)

# scikit-build-core provides SKBUILD_PYTHON_PATH with correct Python
find_package(Python 3.10 COMPONENTS Interpreter Development.Module REQUIRED)
find_package(nanobind CONFIG REQUIRED)

nanobind_add_module(_wgpu FREE_THREADED src/_wgpu.cpp)

install(TARGETS _wgpu DESTINATION gpu/wgpu)

# Generate stubs for type checking support
# Skip for cross-compilation (Pyodide) - stubs generated separately via inject_stub.py
if(NOT CMAKE_CROSSCOMPILING)
    # Delete any existing stub to ensure fresh generation
    file(REMOVE ${CMAKE_CURRENT_SOURCE_DIR}/src/gpu/wgpu/_wgpu.pyi)
    nanobind_add_stub(
        _wgpu_stub
        MODULE _wgpu
        OUTPUT _wgpu.pyi
        PYTHON_PATH $<TARGET_FILE_DIR:_wgpu>
        DEPENDS _wgpu
    )
    # Install stub alongside the compiled module
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/_wgpu.pyi DESTINATION gpu/wgpu)
    # Also copy stub to source directory for IDE support during development
    add_custom_command(
        TARGET _wgpu_stub POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_CURRENT_BINARY_DIR}/_wgpu.pyi
            ${CMAKE_CURRENT_SOURCE_DIR}/src/gpu/wgpu/_wgpu.pyi
        COMMENT "Copying stub to source directory for IDE support"
    )
endif()
