# EDIT: you can use this file from your project: calling
# include(UseOpenMEEG.cmake)
# but it is recommended not to include and link with all includes and libraries,
# but rather to pick what you need
# 
# This file sets up include directories and link directories for a project 
# to use OpenMEEG. 
# It should not be included directly, but rather through the 
# OpenMEEG_USE_FILE setting obtained from OpenMEEGConfig.cmake.
#
#
# Both OpenMEEG_INCLUDE_DIRS and OpenMEEG_LIBRARY_DIRS 
# are defined in OpenMEEGConfig.cmake file
#

# Add include directories needed to use OpenMEEG.
INCLUDE_DIRECTORIES(${OpenMEEG_INCLUDE_DIRS})

# Add link directories needed to use OpenMEEG.
LINK_DIRECTORIES(${OpenMEEG_LIBRARY_DIR})
