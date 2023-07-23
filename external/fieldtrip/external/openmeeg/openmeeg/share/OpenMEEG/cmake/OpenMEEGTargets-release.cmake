#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "OpenMEEGMaths" for configuration "Release"
set_property(TARGET OpenMEEGMaths APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenMEEGMaths PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libOpenMEEGMaths.1.1.0.dylib"
  IMPORTED_SONAME_RELEASE "@rpath/libOpenMEEGMaths.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS OpenMEEGMaths )
list(APPEND _IMPORT_CHECK_FILES_FOR_OpenMEEGMaths "${_IMPORT_PREFIX}/lib/libOpenMEEGMaths.1.1.0.dylib" )

# Import target "OpenMEEG" for configuration "Release"
set_property(TARGET OpenMEEG APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenMEEG PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libOpenMEEG.1.1.0.dylib"
  IMPORTED_SONAME_RELEASE "@rpath/libOpenMEEG.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS OpenMEEG )
list(APPEND _IMPORT_CHECK_FILES_FOR_OpenMEEG "${_IMPORT_PREFIX}/lib/libOpenMEEG.1.1.0.dylib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
