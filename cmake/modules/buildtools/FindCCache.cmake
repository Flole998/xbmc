#.rst:
# FindCCache
# ----------
# Finds ccache and sets it up as compiler wrapper.
# This should ideally be called before the call to project().
#
# See: https://crascit.com/2016/04/09/using-ccache-with-cmake/

find_program(CCACHE_PROGRAM ccache)

if(CCACHE_PROGRAM)
  execute_process(COMMAND "${CCACHE_PROGRAM}" --version
                  OUTPUT_VARIABLE CCACHE_VERSION
                  OUTPUT_STRIP_TRAILING_WHITESPACE)
  string(REGEX MATCH "[^\n]* version [^\n]*" CCACHE_VERSION "${CCACHE_VERSION}")
  string(REGEX REPLACE ".* version (.*)" "\\1" CCACHE_VERSION "${CCACHE_VERSION}")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CCache REQUIRED_VARS CCACHE_PROGRAM
                                  VERSION_VAR CCACHE_VERSION)

if(CCACHE_FOUND)
  if (MSVC)
      file(COPY_FILE ${CCACHE_PROGRAM} ${CMAKE_BINARY_DIR}/cl.exe ONLY_IF_DIFFERENT)
      set(CMAKE_VS_GLOBALS
          "CLToolExe=cl.exe"
          "CLToolPath=${CMAKE_BINARY_DIR}"
          "TrackFileAccess=false"
          "UseMultiToolTask=true"
          "DebugInformationFormat=OldStyle"
      )
      # Replace /Zi with /Z7 in compiler flags, including configuration-specific flags
      string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
      string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
      string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
      string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}")
      string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
      string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
      string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
      string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
      string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL}")
      string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL}")
  else()
    # Supports Unix Makefiles, Ninja and Xcode
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}" PARENT_SCOPE)
    set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}" PARENT_SCOPE)

    file(WRITE "${CMAKE_BINARY_DIR}/launch-c" "#!/bin/sh\nexec \"${CCACHE_PROGRAM}\" \"${CMAKE_C_COMPILER}\" \"$@\"\n")
    file(WRITE "${CMAKE_BINARY_DIR}/launch-cxx" "#!/bin/sh\nexec \"${CCACHE_PROGRAM}\" \"${CMAKE_CXX_COMPILER}\" \"$@\"\n")
    execute_process(COMMAND chmod +x "${CMAKE_BINARY_DIR}/launch-c" "${CMAKE_BINARY_DIR}/launch-cxx")

    set(CMAKE_XCODE_ATTRIBUTE_CC "${CMAKE_BINARY_DIR}/launch-c" PARENT_SCOPE)
    set(CMAKE_XCODE_ATTRIBUTE_CXX "${CMAKE_BINARY_DIR}/launch-cxx" PARENT_SCOPE)
    set(CMAKE_XCODE_ATTRIBUTE_LD "${CMAKE_BINARY_DIR}/launch-c" PARENT_SCOPE)
    set(CMAKE_XCODE_ATTRIBUTE_LDPLUSPLUS "${CMAKE_BINARY_DIR}/launch-cxx" PARENT_SCOPE)
  endif()
endif()

mark_as_advanced(CCACHE_PROGRAM)
