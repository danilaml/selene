#!/usr/bin/env bash

set -e

echo "--------------------------------------------------"
cd selene
echo "COMMIT $(git rev-parse HEAD)"
echo "--------------------------------------------------"
echo "CC = ${CC}"
echo "CXX = ${CXX}"
echo "CXXFLAGS = ${CXXFLAGS}"
echo "LDFLAGS = ${LDFLAGS}"
echo ""
echo "VCPKG_DIR = ${VCPKG_DIR}"
echo "BUILD_TYPE = " ${BUILD_TYPE}
echo "ASAN = ${ASAN}"
echo "--------------------------------------------------"
cmake --version;
echo "--------------------------------------------------"
${CC} --version;
echo "--------------------------------------------------"
${CXX} --version;
echo "--------------------------------------------------"

if [ -n "${VCPKG_DIR}" ]; then
  echo "Building using vcpkg..."
  export LOCAL_VCPKG_TOOLCHAIN="-DCMAKE_TOOLCHAIN_FILE=/home/${VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake"
fi

if [ -n "${BUILD_TYPE}" ]; then
  echo "Build type: ${BUILD_TYPE}"
  export LOCAL_BUILD_TYPE="-DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
fi

if [ -n "${ASAN}" ]; then
  echo "Building with AddressSanitizer enabled..."
  SAN_FLAGS="-fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -fno-optimize-sibling-calls -g -O1"
  export CXXFLAGS="${SAN_FLAGS} ${CXXFLAGS}"
  export LDFLAGS="${SAN_FLAGS} ${LDFLAGS}"
fi

# CMake invocation
rm -rf build && mkdir -p build && cd build
cmake -G Ninja \
  ${LOCAL_BUILD_TYPE} \
  ${LOCAL_VCPKG_TOOLCHAIN} \
  -DSELENE_BUILD_TESTS=ON \
  -DSELENE_BUILD_EXAMPLES=ON \
  -DSELENE_WARNINGS_AS_ERRORS=ON \
  ..

echo "--------------------------------------------------"

# Build all targets
ninja
export SELENE_DATA_PATH=../data

echo "--------------------------------------------------"

# Run tests
./test/selene_tests -d yes

echo "--------------------------------------------------"

# Run all example binaries
# https://stackoverflow.com/questions/4458120/unix-find-search-for-executable-files
EXAMPLE_BINARIES=$(find -L ./examples/ -maxdepth 1 -type f \( -perm -u=x -o -perm -g=x -o -perm -o=x \))
for file in ${EXAMPLE_BINARIES}
do
  echo "EXECUTING ${file}..."
  ${file}
done

echo "FINISHED."

echo "--------------------------------------------------"
