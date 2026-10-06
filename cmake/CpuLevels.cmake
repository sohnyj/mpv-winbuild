# CPU levels the packages can be built for.
#
# add_cpu_level(<level> MARCH <cpu> [FEATURES <feature>...] TUNE <cpu>
#               [RUST_FEATURES <feature>...])
#
# MARCH and TUNE are clang -march and -mtune values, and each of FEATURES is
# added as -m<feature>. Rust code gets MARCH as -C target-cpu and
# RUST_FEATURES, the Rust names of FEATURES, as -C target-feature.
#
# A level is selected with TARGET_LEVEL, and TARGET_TUNE replaces its TUNE.
# To add a level, add an add_cpu_level() call at the end of this file and
# pass its name from the scripts or CI.

include_guard(GLOBAL)

function(add_cpu_level level)
    cmake_parse_arguments(PARSE_ARGV 1 arg "" "MARCH;TUNE" "FEATURES;RUST_FEATURES")
    if(arg_UNPARSED_ARGUMENTS OR NOT arg_MARCH OR NOT arg_TUNE)
        message(FATAL_ERROR "add_cpu_level(${level}): MARCH and TUNE are required")
    endif()
    set_property(GLOBAL APPEND PROPERTY CPU_LEVELS "${level}")
    foreach(key IN ITEMS MARCH TUNE FEATURES RUST_FEATURES)
        set_property(GLOBAL PROPERTY "CPU_LEVEL_${level}_${key}" "${arg_${key}}")
    endforeach()
endfunction()

# cpu_level_flags(<level> <output> [TUNE <cpu>])
#
# Sets <output> to the clang flags of <level>. A non-empty TUNE replaces the
# level's tuning.
function(cpu_level_flags level output)
    cmake_parse_arguments(PARSE_ARGV 2 arg "" "TUNE" "")
    get_property(levels GLOBAL PROPERTY CPU_LEVELS)
    if(NOT level IN_LIST levels)
        message(FATAL_ERROR "Unknown CPU level ${level}; known levels: ${levels}")
    endif()
    get_property(march GLOBAL PROPERTY "CPU_LEVEL_${level}_MARCH")
    get_property(features GLOBAL PROPERTY "CPU_LEVEL_${level}_FEATURES")
    get_property(tune GLOBAL PROPERTY "CPU_LEVEL_${level}_TUNE")
    if(arg_TUNE)
        set(tune "${arg_TUNE}")
    endif()

    set(flags "-march=${march}")
    foreach(feature IN LISTS features)
        list(APPEND flags "-m${feature}")
    endforeach()
    list(APPEND flags "-mtune=${tune}")
    set("${output}" ${flags} PARENT_SCOPE)
endfunction()

# x86-64-v3 with AES-NI and PCLMULQDQ: Intel Haswell and AMD Excavator or
# newer. Highway takes AVX2 as its static target only with both features.
add_cpu_level(x86-64-v3
    MARCH x86-64-v3
    FEATURES
        aes
        pclmul
    TUNE generic
    RUST_FEATURES
        aes
        pclmulqdq
)

# AMD Zen 3 or newer only.
add_cpu_level(znver3
    MARCH znver3
    TUNE znver3
)
