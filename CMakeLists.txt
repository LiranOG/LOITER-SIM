cmake_minimum_required(VERSION 3.20)

# ─────────────────────────────────────────────────────────────────
# Project declaration
# ─────────────────────────────────────────────────────────────────
project(
  loiter_sim
  VERSION 0.0.1
  DESCRIPTION "Deterministic multi-agent UAV swarm simulation engine"
  HOMEPAGE_URL "https://github.com/LiranOG/LOITER-SIM"
  LANGUAGES CXX
)

# ─────────────────────────────────────────────────────────────────
# C++ standard enforcement
# ─────────────────────────────────────────────────────────────────
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)  # No GNU extensions — pure ISO C++17

# ─────────────────────────────────────────────────────────────────
# Build options
# ─────────────────────────────────────────────────────────────────
option(LOITER_SIM_BUILD_TESTS       "Build unit tests"              ON)
option(LOITER_SIM_BUILD_BENCHMARKS  "Build benchmarks"              OFF)
option(LOITER_SIM_BUILD_PYTHON      "Build Python bindings"         OFF)
option(LOITER_SIM_ENABLE_ASAN       "Enable AddressSanitizer"       OFF)
option(LOITER_SIM_ENABLE_UBSAN      "Enable UndefinedBehaviorSan"   OFF)
option(LOITER_SIM_DETERMINISM_TESTS "Enable determinism regression" OFF)

# ─────────────────────────────────────────────────────────────────
# Compile flags
# ─────────────────────────────────────────────────────────────────
add_library(loiter_compile_options INTERFACE)

target_compile_options(loiter_compile_options INTERFACE
  $<$<CXX_COMPILER_ID:GNU,Clang>:
    -Wall
    -Wextra
    -Wpedantic
    -Wconversion
    -Wshadow
    -Wno-unused-parameter
    # Floating-point: strict IEEE 754, no unsafe optimizations
    -mfpmath=sse
    -msse2
    -fno-unsafe-math-optimizations
    -ffp-contract=off
  >
  $<$<CONFIG:Release>:
    -O3
    -march=native
    -DNDEBUG
  >
  $<$<CONFIG:Debug>:
    -O0
    -g3
    -fno-omit-frame-pointer
  >
)

# Sanitizers
if(LOITER_SIM_ENABLE_ASAN OR LOITER_SIM_ENABLE_UBSAN)
  set(SAN_FLAGS "")
  if(LOITER_SIM_ENABLE_ASAN)
    list(APPEND SAN_FLAGS "-fsanitize=address")
  endif()
  if(LOITER_SIM_ENABLE_UBSAN)
    list(APPEND SAN_FLAGS "-fsanitize=undefined")
  endif()
  target_compile_options(loiter_compile_options INTERFACE ${SAN_FLAGS})
  target_link_options(loiter_compile_options INTERFACE ${SAN_FLAGS})
endif()

# ─────────────────────────────────────────────────────────────────
# Dependencies
# ─────────────────────────────────────────────────────────────────
include(cmake/dependencies.cmake)

# ─────────────────────────────────────────────────────────────────
# Core library
# ─────────────────────────────────────────────────────────────────
add_library(loiter_sim_core STATIC)

target_sources(loiter_sim_core PRIVATE
  # Populated as source files are added
  # core/ecs/world.cpp
  # core/dynamics/rigid_body_6dof.cpp
  # ...
)

target_include_directories(loiter_sim_core
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(loiter_sim_core
  PUBLIC
    loiter_compile_options
    Eigen3::Eigen
    hdf5::hdf5
    yaml-cpp::yaml-cpp
)

# ─────────────────────────────────────────────────────────────────
# Python bindings
# ─────────────────────────────────────────────────────────────────
if(LOITER_SIM_BUILD_PYTHON)
  find_package(Python REQUIRED COMPONENTS Interpreter Development)
  find_package(pybind11 REQUIRED)

  pybind11_add_module(loiter_sim_py bindings/loiter_sim_bindings.cpp)
  target_link_libraries(loiter_sim_py PRIVATE loiter_sim_core)
  set_target_properties(loiter_sim_py PROPERTIES OUTPUT_NAME "loiter_sim")
endif()

# ─────────────────────────────────────────────────────────────────
# Tests
# ─────────────────────────────────────────────────────────────────
if(LOITER_SIM_BUILD_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()

# ─────────────────────────────────────────────────────────────────
# Benchmarks
# ─────────────────────────────────────────────────────────────────
if(LOITER_SIM_BUILD_BENCHMARKS)
  add_subdirectory(benchmarks)
endif()

# ─────────────────────────────────────────────────────────────────
# Install rules
# ─────────────────────────────────────────────────────────────────
include(GNUInstallDirs)

install(TARGETS loiter_sim_core loiter_compile_options
  EXPORT loiter_sim_targets
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(DIRECTORY core/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/loiter_sim
  FILES_MATCHING PATTERN "*.hpp"
)

install(EXPORT loiter_sim_targets
  FILE loiter_sim_targets.cmake
  NAMESPACE loiter_sim::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/loiter_sim
)

# ─────────────────────────────────────────────────────────────────
# Format target (clang-format)
# ─────────────────────────────────────────────────────────────────
find_program(CLANG_FORMAT clang-format clang-format-17 clang-format-16)
if(CLANG_FORMAT)
  file(GLOB_RECURSE ALL_SOURCE_FILES
    "${CMAKE_SOURCE_DIR}/core/*.cpp"
    "${CMAKE_SOURCE_DIR}/core/*.hpp"
    "${CMAKE_SOURCE_DIR}/bindings/*.cpp"
    "${CMAKE_SOURCE_DIR}/tests/*.cpp"
  )
  add_custom_target(format
    COMMAND ${CLANG_FORMAT} -i ${ALL_SOURCE_FILES}
    COMMENT "Running clang-format on all source files"
  )
endif()
