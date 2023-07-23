macro(find type arg)
    set(guard "USE_SYSTEM_${arg}")
    if (${guard})
        unset(${arg}_DIR)
    endif()

    if (FIND_DEBUG_MODE)
        set(CMAKE_FIND_DEBUG_MODE 1)
        message("[[Looking for ${type}: ${arg}]]")
    endif()   

    if ("${type}" STREQUAL "package")
        find_package(${arg} ${ARGN})
    elseif ("${type}" STREQUAL "library")
        find_library(${arg} ${arg} ${ARGN})
    else()
        message(SEND_ERROR "Unknown type ${type}")
    endif()
endmacro()

set(FIND_DEBUG_MODE 1)
find(package matio COMPONENTS  PATHS ${matio_DIR} NO_DEFAULT_PATH QUIET CONFIG)
find(package matio COMPONENTS  MODULE QUIET)
find(package matio REQUIRED)

find(package VTK COMPONENTS vtkIOXML;vtkIOLegacy PATHS ${VTK_DIR} NO_DEFAULT_PATH QUIET CONFIG)
find(package VTK COMPONENTS vtkIOXML;vtkIOLegacy MODULE QUIET)
find(package VTK REQUIRED)

find(package vecLib COMPONENTS  PATHS ${vecLib_DIR} NO_DEFAULT_PATH QUIET CONFIG)
find(package vecLib COMPONENTS  MODULE QUIET)
find(package vecLib REQUIRED)

