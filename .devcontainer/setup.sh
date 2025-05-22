#!/bin/bash
set -e

echo "Setting up DOLFINx-MPC development environment..."

# Create cache directory
mkdir -p /tmp/cache

# Upgrade pip and install basic tools
python3 -m pip install --upgrade setuptools pip

# Install Python development tools
python3 -m pip install ruff mypy coverage mpi4py pytest scikit-build-core nanobind

# Install h5py (following workflow pattern)
python3 -m pip install --no-build-isolation --no-cache-dir --no-binary=h5py h5py

# Restrict CFFI version (as done in workflow)
python3 -m pip install --no-build-isolation "cffi<1.17"

# Install DOLFINx dependencies following the GitHub action pattern
echo "Installing DOLFINx..."
cd /tmp

# Install UFL
git clone --depth 1 -b ${UFL_BRANCH:-main} https://github.com/FEniCS/ufl.git
python3 -m pip install --break-system-packages ./ufl

# Install Basix
git clone --depth 1 -b ${BASIX_BRANCH:-main} https://github.com/FEniCS/basix.git
cmake -G Ninja -B build-basix -DCMAKE_BUILD_TYPE=Release -S ./basix/cpp/
cmake --build build-basix --parallel 2
cmake --install build-basix
python3 -m pip install --break-system-packages --check-build-dependencies --config-settings=build-dir="build-basix-python" --config-settings=cmake.build-type=Release --config-settings=install.strip=false --no-build-isolation ./basix/python

# Install FFCx
git clone --depth 1 -b ${FFCX_BRANCH:-main} https://github.com/FEniCS/ffcx.git
python3 -m pip install --break-system-packages ./ffcx

# Install DOLFINx
git clone --depth 1 -b ${DOLFINX_BRANCH:-main} https://github.com/FEniCS/dolfinx.git
cd dolfinx

# Build C++ library
PETSC_DIR=/usr/local/petsc PETSC_ARCH=${PETSC_ARCH} cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -B build-dolfinx -S ./cpp/
cmake --build build-dolfinx
cmake --install build-dolfinx

# Build Python interface
python3 -m pip install --break-system-packages -r ./python/build-requirements.txt
PETSC_DIR=/usr/local/petsc PETSC_ARCH=${PETSC_ARCH} python3 -m pip install --break-system-packages --check-build-dependencies --no-build-isolation --no-dependencies ./python/

cd /workspaces/dolfinx_mpc

echo "Development environment setup complete!"
echo ""
echo "To build the project:"
echo "1. Build C++ component:"
echo "   cmake -G Ninja -B build-dir -DCMAKE_BUILD_TYPE="${MPC_BUILD_MODE}" -DCMAKE_CXX_FLAGS="${MPC_CMAKE_CXX_FLAGS}" -S cpp/
echo "   cmake --build build-dir"
echo "   cmake --install build-dir"
echo ""
echo "2. Install Python component:"
echo "   python3 -m pip install --config-settings=cmake.build-type="${MPC_BUILD_MODE}" --no-build-isolation -e python/[all]"
echo ""
echo "3. Run tests:"
echo "   pytest python/tests/ -vs"
echo "   mpirun -n 2 pytest python/tests/ -vs"