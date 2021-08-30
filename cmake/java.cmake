# Will need swig
set(CMAKE_SWIG_FLAGS)
find_package(SWIG REQUIRED)
include(UseSWIG)

if(${SWIG_VERSION} VERSION_GREATER_EQUAL 4)
  list(APPEND CMAKE_SWIG_FLAGS "-doxygen")
endif()

if(UNIX AND NOT APPLE)
  list(APPEND CMAKE_SWIG_FLAGS "-DSWIGWORDSIZE64")
endif()

# Find Java
find_package(Java 1.8 COMPONENTS Development REQUIRED)
find_package(JNI REQUIRED)

# Find maven
# On windows mvn spawn a process while mvn.cmd is a blocking command
if(UNIX)
  find_program(MAVEN_EXECUTABLE mvn)
else()
  find_program(MAVEN_EXECUTABLE mvn.cmd)
endif()
if(NOT MAVEN_EXECUTABLE)
  message(FATAL_ERROR "Check for maven Program: not found")
else()
  message(STATUS "Found Maven: ${MAVEN_EXECUTABLE}")
endif()

# Needed by java/CMakeLists.txt
set(JAVA_PACKAGE org.mizux.javanative)
set(JAVA_PACKAGE_PATH src/main/java/org/mizux/javanative)
  set(JAVA_TEST_PATH src/test/java/org/mizux/javanative)
set(JAVA_RESOURCES_PATH src/main/resources)
if(APPLE)
  set(NATIVE_IDENTIFIER darwin-x86-64)
elseif(UNIX)
  set(NATIVE_IDENTIFIER linux-x86-64)
elseif(WIN32)
  set(NATIVE_IDENTIFIER win32-x86-64)
else()
  message(FATAL_ERROR "Unsupported system !")
endif()
set(JAVA_NATIVE_PROJECT javanative-${NATIVE_IDENTIFIER})
set(JAVA_PROJECT javanative-java)

# Create the native library
add_library(jnijavanative SHARED "")
set_target_properties(jnijavanative PROPERTIES
  POSITION_INDEPENDENT_CODE ON)
# note: macOS is APPLE and also UNIX !
if(APPLE)
  set_target_properties(jnijavanative PROPERTIES INSTALL_RPATH "@loader_path")
  # Xcode fails to build if library doesn't contains at least one source file.
  if(XCODE)
    file(GENERATE
      OUTPUT ${PROJECT_BINARY_DIR}/jnijavanative/version.cpp
      CONTENT "namespace {char* version = \"${PROJECT_VERSION}\";}")
    target_sources(jnijavanative PRIVATE ${PROJECT_BINARY_DIR}/jnijavanative/version.cpp)
  endif()
elseif(UNIX)
  set_target_properties(jnijavanative PROPERTIES INSTALL_RPATH "$ORIGIN")
endif()

# Swig wrap all libraries
foreach(SUBPROJECT IN ITEMS Foo)
  add_subdirectory(${SUBPROJECT}/java)
  target_link_libraries(jnijavanative PRIVATE jni${SUBPROJECT})
endforeach()

#################################
##  Java Native Maven Package  ##
#################################
set(JAVA_NATIVE_PROJECT_PATH ${PROJECT_BINARY_DIR}/java/${JAVA_NATIVE_PROJECT})
file(MAKE_DIRECTORY ${JAVA_NATIVE_PROJECT_PATH}/${JAVA_RESOURCES_PATH}/${JAVA_NATIVE_PROJECT})

configure_file(
  ${PROJECT_SOURCE_DIR}/java/pom-native.xml.in
  ${JAVA_NATIVE_PROJECT_PATH}/pom.xml
  @ONLY)

add_custom_target(java_native_package
  DEPENDS
  ${JAVA_NATIVE_PROJECT_PATH}/pom.xml
  COMMAND ${CMAKE_COMMAND} -E copy
    $<TARGET_FILE:jnijavanative>
    $<$<NOT:$<PLATFORM_ID:Windows>>:$<TARGET_SONAME_FILE:Foo>>
    ${JAVA_RESOURCES_PATH}/${JAVA_NATIVE_PROJECT}/
  COMMAND ${MAVEN_EXECUTABLE} compile -B
  COMMAND ${MAVEN_EXECUTABLE} package -B
  COMMAND ${MAVEN_EXECUTABLE} install -B $<$<BOOL:${SKIP_GPG}>:-Dgpg.skip=true>
  BYPRODUCTS
    ${JAVA_NATIVE_PROJECT_PATH}/target
  WORKING_DIRECTORY ${JAVA_NATIVE_PROJECT_PATH})

##########################
##  Java Maven Package  ##
##########################
set(JAVA_PROJECT_PATH ${PROJECT_BINARY_DIR}/java/${JAVA_PROJECT})
file(MAKE_DIRECTORY ${JAVA_PROJECT_PATH}/${JAVA_PACKAGE_PATH})

configure_file(
  ${PROJECT_SOURCE_DIR}/java/pom-local.xml.in
  ${JAVA_PROJECT_PATH}/pom.xml
  @ONLY)

add_custom_target(java_package ALL
  DEPENDS
  ${JAVA_PROJECT_PATH}/pom.xml
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/java/Loader.java ${JAVA_PACKAGE_PATH}/
  COMMAND ${MAVEN_EXECUTABLE} compile -B
  COMMAND ${MAVEN_EXECUTABLE} package -B
  COMMAND ${MAVEN_EXECUTABLE} install -B $<$<BOOL:${SKIP_GPG}>:-Dgpg.skip=true>
  BYPRODUCTS
    ${JAVA_PROJECT_PATH}/target
  WORKING_DIRECTORY ${JAVA_PROJECT_PATH})
add_dependencies(java_package java_native_package)

#################
##  Java Test  ##
#################
if(BUILD_TESTING)
  set(TEST_PATH ${PROJECT_BINARY_DIR}/java/tests/javanative-test)
  file(MAKE_DIRECTORY ${TEST_PATH}/${JAVA_TEST_PATH})

  file(COPY ${PROJECT_SOURCE_DIR}/java/FooTest.java
    DESTINATION ${TEST_PATH}/${JAVA_TEST_PATH})

  set(JAVA_TEST_PROJECT javanative-test)
  configure_file(
    ${PROJECT_SOURCE_DIR}/java/pom-test.xml.in
    ${TEST_PATH}/pom.xml
    @ONLY)

  add_custom_target(java_test_Test ALL
    DEPENDS ${TEST_PATH}/pom.xml
    COMMAND ${MAVEN_EXECUTABLE} compile -B
    BYPRODUCTS
      ${TEST_PATH}/target
    WORKING_DIRECTORY ${TEST_PATH})
  add_dependencies(java_test_Test java_package)

  add_test(
    NAME java_FooTest
    COMMAND ${MAVEN_EXECUTABLE} test
    WORKING_DIRECTORY ${TEST_PATH})
endif()
