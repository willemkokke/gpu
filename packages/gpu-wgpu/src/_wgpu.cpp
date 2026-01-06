#include <nanobind/nanobind.h>

namespace nb = nanobind;

int add(int a, int b) {
    return a + b;
}

const char* get_backend_name() {
    return "wgpu-native-dummy";
}

NB_MODULE(_wgpu, m) {
    m.doc() = "wgpu-native WebGPU bindings (dummy)";
    m.def("add", &add, "Add two numbers.", nb::arg("a"), nb::arg("b"));
    m.def("get_backend_name", &get_backend_name, "Get backend name.");
}
