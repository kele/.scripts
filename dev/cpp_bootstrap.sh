set -e

PROJECTNAME="$1"

if [ -z "${PROJECTNAME}" ]; then
    echo "Usage: cpp_bootstrap.sh <project_name>"
    exit 1
fi

# Setup CMake
mkdir src
mkdir tst

cat > CMakeLists.txt << EOL
cmake_minimum_required (VERSION 2.6)

project (${PROJECTNAME})

set (SRC \${PROJECT_SOURCE_DIR}/src)

set (CMAKE_CXX_FLAGS "\${CMAKE_CXX_FLAGS} -Wall -pedantic -std=c++17 -g")
set (CMAKE_EXECUTABLE_SUFFIX ".out")

include_directories(\${SRC})

file(GLOB_RECURSE ALL_SOURCE_FILES \${SRC}/*.cpp \${SRC}/*.hpp)

set (TST \${PROJECT_SOURCE_DIR}/tst)
file(GLOB_RECURSE ALL_TST_FILES \${TST}/*.cpp \${TST}/*.hpp)

add_subdirectory (tst)

add_custom_target(
        clangformat
        COMMAND clang-format
        -style=LLVM
        -i
        \${ALL_SOURCE_FILES}
        \${ALL_TST_FILES}
)
EOL


cat > tst/CMakeLists.txt << EOL
set(SOURCES
    run.cpp
    \${ALL_SOURCE_FILES}
)

file(GLOB_RECURSE TEST_SUITES test_*.cpp)
add_executable (test_all
    \${TEST_SUITES}
    \${SOURCES}
)

set_target_properties(test_all PROPERTIES COMPILE_FLAGS "-DDEBUG -I\${CMAKE_CURRENT_LIST_DIR}")
EOL

# Build directory
mkdir build

# Creating wrappers for clang_complete
cat > build/wrapper_cxx.sh << EOL
~/.vim/bundle/clang_complete/bin/cc_args.py clang++ \$@
EOL

chmod +x build/wrapper_cxx.sh

cat > build/wrapper_cc.sh << EOL
~/.vim/bundle/clang_complete/bin/cc_args.py clang \$@
EOL

chmod +x build/wrapper_cc.sh

pushd build
CXX=`pwd`/wrapper_cxx.sh CC=`pwd`/wrapper_cc.sh cmake ..
popd
