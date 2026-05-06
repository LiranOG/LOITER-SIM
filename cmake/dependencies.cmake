include(FetchContent)

# ─────────────────────────────────────────────────────────────────
# Eigen3 — linear algebra
# Pinned: 3.4.0 (stable release)
# ─────────────────────────────────────────────────────────────────
find_package(Eigen3 3.4 QUIET)
if(NOT Eigen3_FOUND)
  FetchContent_Declare(
    Eigen3
    GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git
    GIT_TAG 3.4.0
    GIT_SHALLOW TRUE
  )
  set(EIGEN_BUILD_TESTING OFF CACHE BOOL "" FORCE)
  set(EIGEN_BUILD_DOC     OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(Eigen3)
endif()

# ─────────────────────────────────────────────────────────────────
# yaml-cpp — YAML scenario parsing
# Pinned: 0.8.0
# ─────────────────────────────────────────────────────────────────
find_package(yaml-cpp 0.8 QUIET)
if(NOT yaml-cpp_FOUND)
  FetchContent_Declare(
    yaml-cpp
    GIT_REPOSITORY https://github.com/jbeder/yaml-cpp.git
    GIT_TAG 0.8.0
    GIT_SHALLOW TRUE
  )
  set(YAML_CPP_BUILD_TESTS   OFF CACHE BOOL "" FORCE)
  set(YAML_CPP_BUILD_TOOLS   OFF CACHE BOOL "" FORCE)
  set(YAML_CPP_BUILD_CONTRIB OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(yaml-cpp)
endif()

# ─────────────────────────────────────────────────────────────────
# HDF5 — checkpoints and aerodynamic lookup tables
# System package preferred; FetchContent fallback not available for HDF5.
# ─────────────────────────────────────────────────────────────────
find_package(HDF5 REQUIRED COMPONENTS CXX)
if(NOT TARGET hdf5::hdf5)
  add_library(hdf5::hdf5 INTERFACE IMPORTED)
  target_include_directories(hdf5::hdf5 INTERFACE ${HDF5_INCLUDE_DIRS})
  target_link_libraries(hdf5::hdf5 INTERFACE ${HDF5_LIBRARIES})
endif()

# ─────────────────────────────────────────────────────────────────
# GoogleTest — unit testing (only if tests enabled)
# Pinned: 1.14.0
# ─────────────────────────────────────────────────────────────────
if(LOITER_SIM_BUILD_TESTS)
  FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.14.0
    GIT_SHALLOW TRUE
  )
  set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
  set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(googletest)
endif()

# ─────────────────────────────────────────────────────────────────
# Google Benchmark (only if benchmarks enabled)
# Pinned: 1.8.4
# ─────────────────────────────────────────────────────────────────
if(LOITER_SIM_BUILD_BENCHMARKS)
  FetchContent_Declare(
    benchmark
    GIT_REPOSITORY https://github.com/google/benchmark.git
    GIT_TAG v1.8.4
    GIT_SHALLOW TRUE
  )
  set(BENCHMARK_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(benchmark)
endif()

# ─────────────────────────────────────────────────────────────────
# PyBind11 (only if Python bindings enabled)
# Pinned: 2.11.1
# ─────────────────────────────────────────────────────────────────
if(LOITER_SIM_BUILD_PYTHON)
  FetchContent_Declare(
    pybind11
    GIT_REPOSITORY https://github.com/pybind/pybind11.git
    GIT_TAG v2.11.1
    GIT_SHALLOW TRUE
  )
  FetchContent_MakeAvailable(pybind11)
endif()
