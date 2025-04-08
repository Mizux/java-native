# Download and unpack swig at configure time
message(CHECK_START "Fetching SWIG")
list(APPEND CMAKE_MESSAGE_INDENT "  ")
configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/SWIG.CMakeLists.txt.in
  ${CMAKE_CURRENT_BINARY_DIR}/SWIG/CMakeLists.txt
  @ONLY
)

execute_process(
  COMMAND ${CMAKE_COMMAND} -H. -Bproject_build -G "${CMAKE_GENERATOR}"
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/SWIG)
if(result)
  message(FATAL_ERROR "CMake step for SWIG failed: ${result}")
endif()

execute_process(
  COMMAND ${CMAKE_COMMAND} --build project_build --config Release
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/SWIG)
if(result)
  message(FATAL_ERROR "Build step for SWIG failed: ${result}")
endif()

set(SWIG_EXECUTABLE
  ${CMAKE_CURRENT_BINARY_DIR}/SWIG/source/swig.exe
  CACHE INTERNAL "swig.exe location" FORCE)
list(POP_BACK CMAKE_MESSAGE_INDENT)
message(CHECK_PASS "fetched")
