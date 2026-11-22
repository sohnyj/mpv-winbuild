# cmake -D STAMP_DIR=<directory> -P DeleteStamps.cmake
#
# Deletes stamps of an external project, so that all its steps run again.
# Stamps are the empty files of STAMP_DIR, since ExternalProject
# creates them by touching. An empty log there is deleted with them.

file(GLOB files LIST_DIRECTORIES false "${STAMP_DIR}/*")
foreach(file IN LISTS files)
    file(SIZE "${file}" size)
    if(size EQUAL 0)
        file(REMOVE "${file}")
    endif()
endforeach()
