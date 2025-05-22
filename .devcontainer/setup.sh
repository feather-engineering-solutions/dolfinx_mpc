#!/bin/bash
set -e

echo "Setting up DOLFINx-MPC development environment..."

# Create cache directory
mkdir -p /tmp/cache

# Upgrade pip and install basic tools
python3 -m pip install --upgrade setuptools pip

# Install Python development tools
python3 -m pip install ruff mypy coverage mpi4py pytest

# Install h5py (following workflow pattern)
python3 -m pip install --no-build-isolation --no-cache-dir --no-binary=h5py h5py

# Restrict CFFI version (as done in workflow)
python3 -m pip install --no-build-isolation "cffi<1.17"

echo "Development environment setup complete!"
echo ""
echo "To build the project:"
echo "1. Build C++ component:"
echo "   cmake -G Ninja -B build-dir -DCMAKE_BUILD_TYPE=\${MPC_BUILD_MODE} -DCMAKE_CXX_FLAGS=\${MPC_CMAKE_CXX_FLAGS} -S cpp/"
echo "   cmake --build build-dir"
echo "   cmake --install build-dir"
echo ""
echo "2. Install Python component:"
echo "   python3 -m pip install --config-settings=cmake.build-type=\${MPC_BUILD_MODE} --no-build-isolation -e python/[test,optional]"
echo ""
echo "3. Run tests:"
echo "   pytest python/tests/ -vs"
echo "   mpirun -n 2 pytest python/tests/ -vs"