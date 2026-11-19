# cmake -D STAMP_DIR=<directory> -P DeleteStamps.cmake
#
# Deletes the stamps of an external project, so that all of its steps run
# again. The stamps are the empty files of STAMP_DIR, since ExternalProject
# creates them by touching; an empty log there goes with them.

file(GLOB files LIST_DIRECTORIES false "${STAMP_DIR}/*")
foreach(file IN LISTS files)
    file(SIZE "${file}" size)
    if(size EQUAL 0)
        file(REMOVE "${file}")
    endif()
endforeach()
