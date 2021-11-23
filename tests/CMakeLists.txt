if(NOT BUILD_TESTING)
  return()
endif()

file(GLOB JAVA_SRCS "*.java")
foreach(FILE_NAME IN LISTS JAVA_SRCS)
  add_java_test(${FILE_NAME})
endforeach()
