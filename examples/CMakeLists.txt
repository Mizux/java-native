if(NOT BUILD_EXAMPLES)
  return()
endif()

file(GLOB CPP_SRCS "*.cpp")
foreach(FILE_NAME IN LISTS CPP_SRCS)
  add_cpp_example(${FILE_NAME})
endforeach()

file(GLOB JAVA_SRCS "*.java")
foreach(FILE_NAME IN LISTS JAVA_SRCS)
  add_java_example(${FILE_NAME})
endforeach()
