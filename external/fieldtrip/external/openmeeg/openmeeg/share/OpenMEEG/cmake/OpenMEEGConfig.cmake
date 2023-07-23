# Config file for the OpenMEEG package
# It defines the following variables
#     OpenMEEG_INCLUDE_DIRS - include directories for FooBar
#     OpenMEEG_LIBRARIES    - libraries to link against
#     OpenMEEG_LIBRARY_DIRS - libraries to link against
#     OpenMEEG_EXECUTABLE   - the executable
 
# Tell the user project where to find our headers and libraries

# Our library dependencies (contains definitions for IMPORTED targets)

string(TOUPPER OpenMEEG UpperConfigName)
string(TOLOWER OpenMEEG LowerConfigName)
set(OpenMEEG_VERSION )
set(${UpperConfigName}_VERSION )

####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was XXXConfig.cmake.in                            ########

get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

macro(set_and_check _var _file)
  set(${_var} "${_file}")
  if(NOT EXISTS "${_file}")
    message(FATAL_ERROR "File or directory ${_file} referenced by variable ${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT ${_NAME}_${comp}_FOUND)
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

####################################################################################

#   These are IMPORTED targets created by OpenMEEGLibraryDepends.cmake

set_and_check(OpenMEEG_ROOT_DIR    "${PACKAGE_PREFIX_DIR}")
set_and_check(OpenMEEG_CONFIG_DIR  "${PACKAGE_PREFIX_DIR}/share")
set_and_check(OpenMEEG_LIBRARY_DIR "${PACKAGE_PREFIX_DIR}/lib")
set_and_check(OpenMEEG_INCLUDE_DIR "${PACKAGE_PREFIX_DIR}/include/${LowerConfigName}")
set_and_check(OpenMEEG_CMAKE_DIR   "${PACKAGE_PREFIX_DIR}/share/OpenMEEG/cmake")

# Dependencies: we need to install the FindDependencies too..
list(APPEND CMAKE_MODULE_PATH ${OpenMEEG_CMAKE_DIR})

set(OpenMEEG_LIBRARY_DEPENDS_FILE "${PACKAGE_PREFIX_DIR}/share/OpenMEEG/cmake/OpenMEEGDependencies.cmake")
if (NOT OpenMEEG_NO_LIBRARY_DEPENDS AND EXISTS "${OpenMEEG_LIBRARY_DEPENDS_FILE}")
    include(${OpenMEEG_LIBRARY_DEPENDS_FILE})
endif()
 

set(OpenMEEG_INCLUDE_DIRS ${OpenMEEG_INCLUDE_DIR}  ${matio_INCLUDE_DIRS} ${matio_INCLUDE_DIR} ${VTK_INCLUDE_DIRS} ${VTK_INCLUDE_DIR} ${vecLib_INCLUDE_DIRS} ${vecLib_INCLUDE_DIR})

if (OpenMEEG_INCLUDE_DIRS)
    list(REMOVE_DUPLICATES OpenMEEG_INCLUDE_DIRS)
endif()

if (OpenMEEG_LIBRARY_DIRS)
    list(REMOVE_DUPLICATES OpenMEEG_LIBRARY_DIRS)
endif()

set(_libs)
foreach (i OpenMEEG;OpenMEEGMaths)
    set(CMAKE_FIND_DEBUG_MODE 1)
    find_library(var_${i} ${i} HINTS ${OpenMEEG_LIBRARY_DIR})
    if (NOT var_${i})
        message(SEND_ERROR "Library ${i} not found.")
    endif()
    set(_libs ${_libs} ${var_${i}})
endforeach()
set(OpenMEEG_LIBRARIES ${_libs}  ${matio_LIBRARIES} ${VTK_LIBRARIES} ${vecLib_LIBRARIES})

if(NOT TARGET OpenMEEG)
    include(${OpenMEEG_CMAKE_DIR}/OpenMEEGTargets.cmake)
endif()

set(OpenMEEG_USE_FILE "${OpenMEEG_CMAKE_DIR}/UseOpenMEEG.cmake" )

# check_required_components(OpenMEEG) # <- XXX does not work !??
check_required_components(OpenMEEGMaths)
