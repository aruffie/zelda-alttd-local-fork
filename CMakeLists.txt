cmake_minimum_required(VERSION 2.6)
project(ZELDA_ALTTD)

set(quest_name "zelda-alttd")

# data files list
file(GLOB_RECURSE data_files
  RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/data
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.spc
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.ogg
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.it
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.png
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.dat
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.lua
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.ttf
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.ttc
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.fon
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.glsl
)

file(GLOB_RECURSE data_files_prefixed
  RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.spc
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.ogg
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.it
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.png
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.dat
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.lua
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.ttf
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.ttc
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.fon
  ${CMAKE_CURRENT_SOURCE_DIR}/data/*.glsl
)

# add other data to zip archive
add_custom_command(
  OUTPUT data.solarus
  DEPENDS ${data_files_prefixed}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data
  COMMAND zip -q ${CMAKE_CURRENT_BINARY_DIR}/data.solarus ${data_files}
)

add_custom_target(${quest_name}_data
  ALL
  DEPENDS data.solarus
)

# create a script that executes the engine with this quest
add_custom_command(
  OUTPUT ${quest_name}
  COMMAND echo '\#!/bin/bash' > ${quest_name}
  COMMAND echo 'solarus ${CMAKE_INSTALL_PREFIX}/share/solarus/${quest_name} $*' >> ${quest_name}
)
add_custom_target(${quest_name}_command
  ALL
  DEPENDS ${quest_name}
)

# install the data archive
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/data.solarus
  DESTINATION share/solarus/${quest_name}
)

# install the script
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/${quest_name}
  DESTINATION bin
)

