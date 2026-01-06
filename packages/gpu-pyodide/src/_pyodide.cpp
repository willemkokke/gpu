#include <nanobind/nanobind.h>

namespace nb = nanobind;

int add(int a, int b) {
    return a + b;
}

const char* get_backend_name() {
    return "dawn-emscripten-dummy";
}

NB_MODULE(_pyodide, m) {
    m.doc() = "Dawn WebGPU bindings for Pyodide (dummy)";
    m.def("add", &add, "Add two numbers.", nb::arg("a"), nb::arg("b"));
    m.def("get_backend_name", &get_backend_name, "Get backend name.");
}
