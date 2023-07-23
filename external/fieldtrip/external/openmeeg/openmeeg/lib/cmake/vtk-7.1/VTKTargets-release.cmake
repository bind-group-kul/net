#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "vtksys" for configuration "Release"
set_property(TARGET vtksys APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtksys PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtksys-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtksys-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtksys )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtksys "${_IMPORT_PREFIX}/lib/libvtksys-7.1.1.dylib" )

# Import target "vtkCommonCore" for configuration "Release"
set_property(TARGET vtkCommonCore APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkCommonCore PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkCommonCore-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkCommonCore-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkCommonCore )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkCommonCore "${_IMPORT_PREFIX}/lib/libvtkCommonCore-7.1.1.dylib" )

# Import target "vtkCommonMath" for configuration "Release"
set_property(TARGET vtkCommonMath APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkCommonMath PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkCommonMath-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkCommonMath-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkCommonMath )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkCommonMath "${_IMPORT_PREFIX}/lib/libvtkCommonMath-7.1.1.dylib" )

# Import target "vtkCommonMisc" for configuration "Release"
set_property(TARGET vtkCommonMisc APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkCommonMisc PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkCommonMisc-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkCommonMisc-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkCommonMisc )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkCommonMisc "${_IMPORT_PREFIX}/lib/libvtkCommonMisc-7.1.1.dylib" )

# Import target "vtkCommonSystem" for configuration "Release"
set_property(TARGET vtkCommonSystem APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkCommonSystem PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "vtksys"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkCommonSystem-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkCommonSystem-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkCommonSystem )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkCommonSystem "${_IMPORT_PREFIX}/lib/libvtkCommonSystem-7.1.1.dylib" )

# Import target "vtkCommonTransforms" for configuration "Release"
set_property(TARGET vtkCommonTransforms APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkCommonTransforms PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkCommonTransforms-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkCommonTransforms-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkCommonTransforms )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkCommonTransforms "${_IMPORT_PREFIX}/lib/libvtkCommonTransforms-7.1.1.dylib" )

# Import target "vtkCommonDataModel" for configuration "Release"
set_property(TARGET vtkCommonDataModel APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkCommonDataModel PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "vtkCommonMisc;vtkCommonSystem;vtksys"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkCommonDataModel-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkCommonDataModel-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkCommonDataModel )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkCommonDataModel "${_IMPORT_PREFIX}/lib/libvtkCommonDataModel-7.1.1.dylib" )

# Import target "vtkCommonExecutionModel" for configuration "Release"
set_property(TARGET vtkCommonExecutionModel APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkCommonExecutionModel PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "vtkCommonMisc;vtkCommonSystem"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkCommonExecutionModel-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkCommonExecutionModel-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkCommonExecutionModel )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkCommonExecutionModel "${_IMPORT_PREFIX}/lib/libvtkCommonExecutionModel-7.1.1.dylib" )

# Import target "vtkIOCore" for configuration "Release"
set_property(TARGET vtkIOCore APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkIOCore PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "vtkCommonDataModel;vtkCommonMisc;vtksys"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkIOCore-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkIOCore-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkIOCore )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkIOCore "${_IMPORT_PREFIX}/lib/libvtkIOCore-7.1.1.dylib" )

# Import target "vtkIOLegacy" for configuration "Release"
set_property(TARGET vtkIOLegacy APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkIOLegacy PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "vtkCommonMisc;vtksys"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkIOLegacy-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkIOLegacy-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkIOLegacy )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkIOLegacy "${_IMPORT_PREFIX}/lib/libvtkIOLegacy-7.1.1.dylib" )

# Import target "vtkexpat" for configuration "Release"
set_property(TARGET vtkexpat APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkexpat PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkexpat-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkexpat-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkexpat )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkexpat "${_IMPORT_PREFIX}/lib/libvtkexpat-7.1.1.dylib" )

# Import target "vtkIOXMLParser" for configuration "Release"
set_property(TARGET vtkIOXMLParser APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkIOXMLParser PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "vtkIOCore;vtkexpat"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkIOXMLParser-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkIOXMLParser-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkIOXMLParser )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkIOXMLParser "${_IMPORT_PREFIX}/lib/libvtkIOXMLParser-7.1.1.dylib" )

# Import target "vtkIOXML" for configuration "Release"
set_property(TARGET vtkIOXML APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(vtkIOXML PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "vtkCommonDataModel;vtkCommonMisc;vtkCommonSystem;vtkIOCore;vtksys"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libvtkIOXML-7.1.1.dylib"
  IMPORTED_SONAME_RELEASE "libvtkIOXML-7.1.1.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS vtkIOXML )
list(APPEND _IMPORT_CHECK_FILES_FOR_vtkIOXML "${_IMPORT_PREFIX}/lib/libvtkIOXML-7.1.1.dylib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
