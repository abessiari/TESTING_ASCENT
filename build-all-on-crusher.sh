#!/bin/bash

##############################################################################
# Demonstrates how to manually build Ascent and its dependencies, including:
#
#  hdf5, conduit, vtk-m, mfem, raja, and umpire
#
# usage example:
#   env enable_mpi=ON enable_openmp=ON ./build_ascent.sh
#
#
# Assumes: 
#  - cmake is in your path
#  - selected compilers are in your path or set via env vars
#  - [when enabled] MPI and Python (+numpy and mpi4py), are in your path
#
##############################################################################
set -eu -o pipefail

module load cmake/3.23.2

##############################################################################
# Build Options
##############################################################################

# shared options
enable_fortran="${enable_fortran:=OFF}"
enable_python="${enable_python:=OFF}"
enable_openmp="${enable_openmp:=OFF}"
enable_mpi="${enable_mpi:=ON}"
enable_tests="${enable_tests:=ON}"
enable_verbose="${enable_verbose:=ON}"
build_jobs="${build_jobs:=6}"

# tpl controls
build_hdf5="${build_hdf5:=false}"
build_conduit="${build_conduit:=true}"
build_vtkm="${build_vtkm:=false}"
build_ascent="${build_ascent:=true}"
build_warpx="${build_warpx:=true}"

root_dir=$(pwd)

################
# HDF5
################
hdf5_version=1.12.2
hdf5_src_dir=${root_dir}/hdf5-${hdf5_version}
hdf5_build_dir=${root_dir}/build/hdf5-${hdf5_version}/
hdf5_install_dir=${root_dir}/install/hdf5-${hdf5_version}/
hdf5_tarball=hdf5-${hdf5_version}.tar.gz

if ${build_hdf5}; then
if [ ! -d ${hdf5_src_dir} ]; then
  echo "**** Downloading ${hdf5_tarball}"
  curl -L https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.2/src/hdf5-1.12.2.tar.gz -o ${hdf5_tarball}
  tar -xzf ${hdf5_tarball}
fi

echo "**** Configuring HDF5 ${hdf5_version}"
cmake -S ${hdf5_src_dir} -B ${hdf5_build_dir} \
  -DCMAKE_VERBOSE_MAKEFILE:BOOL=${enable_verbose} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${hdf5_install_dir}

echo "**** Building HDF5 ${hdf5_version}"
cmake --build ${hdf5_build_dir} -j${build_jobs}
echo "**** Installing HDF5 ${hdf5_version}"
cmake --install ${hdf5_build_dir}

fi # build_hdf5

################
# Conduit
################
conduit_version=v0.8.6
conduit_src_dir=${root_dir}/conduit-${conduit_version}/src
conduit_build_dir=${root_dir}/build/conduit-${conduit_version}/
conduit_install_dir=${root_dir}/install/conduit-${conduit_version}/
conduit_tarball=conduit-${conduit_version}-src-with-blt.tar.gz

if ${build_conduit}; then
if [ ! -d ${conduit_src_dir} ]; then
  echo "**** Downloading ${conduit_tarball}"
  curl -L https://github.com/LLNL/conduit/releases/download/${conduit_version}/${conduit_tarball} -o ${conduit_tarball}
  tar -xzf ${conduit_tarball}
fi

echo "**** Configuring Conduit ${conduit_version}"
cmake -S ${conduit_src_dir} -B ${conduit_build_dir} \
  -DCMAKE_VERBOSE_MAKEFILE:BOOL=${enable_verbose}\
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${conduit_install_dir} \
  -DENABLE_FORTRAN=${enable_fortran} \
  -DENABLE_MPI=${enable_mpi} \
  -DENABLE_PYTHON=${enable_python} \
  -DENABLE_TESTS=${enable_tests} \
  -DHDF5_DIR=${hdf5_install_dir}

echo "**** Building Conduit ${conduit_version}"
cmake --build ${conduit_build_dir} -j${build_jobs}
echo "**** Installing Conduit ${conduit_version}"
cmake --install ${conduit_build_dir}

fi # build_conduit


################
# VTK-m
################
vtkm_version=v1.9.0
vtkm_src_dir=${root_dir}/vtk-m-${vtkm_version}
vtkm_build_dir=${root_dir}/build/vtk-m-${vtkm_version}
vtkm_install_dir=${root_dir}/install/vtk-m-${vtkm_version}/
vtkm_tarball=vtk-m-${vtkm_version}.tar.gz

if ${build_vtkm}; then
if [ ! -d ${vtkm_src_dir} ]; then
  echo "**** Downloading ${vtkm_tarball}"
  curl -L https://gitlab.kitware.com/vtk/vtk-m/-/archive/${vtkm_version}/${vtkm_tarball} -o ${vtkm_tarball}
  tar xvzf ${vtkm_tarball}
fi

echo "**** Configuring VTK-m ${vtkm_version}"
cmake -S ${vtkm_src_dir} -B ${vtkm_build_dir} \
  -DCMAKE_VERBOSE_MAKEFILE:BOOL=${enable_verbose}\
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBUILD_SHARED_LIBS=ON\
  -DVTKm_NO_DEPRECATED_VIRTUAL=ON \
  -DVTKm_USE_64BIT_IDS=OFF \
  -DVTKm_USE_DOUBLE_PRECISION=ON \
  -DVTKm_USE_DEFAULT_TYPES_FOR_ASCENT=ON \
  -DVTKm_ENABLE_MPI=${enable_mpi} \
  -DVTKm_ENABLE_OPENMP=${enable_openmp}\
  -DVTKm_ENABLE_RENDERING=ON \
  -DVTKm_ENABLE_TESTING=OFF \
  -DBUILD_TESTING=OFF \
  -DVTKm_ENABLE_BENCHMARKS=OFF\
  -DCMAKE_INSTALL_PREFIX=${vtkm_install_dir} \
  -DVTKm_ENABLE_EXAMPLES=OFF \
  -DVTKM_EXAMPLE_CONTOURTREE_ENABLE_DEBUG_PRINT=OFF \

echo "**** Building VTK-m ${vtkm_version}"
cmake --build ${vtkm_build_dir} -j${build_jobs}
echo "**** Installing VTK-m ${vtkm_version}"
cmake --install ${vtkm_build_dir}

fi # build_vtkm

################
# Ascent
################
ascent_version=develop
ascent_src_dir=${root_dir}/ascent/src
ascent_build_dir=${root_dir}/build/ascent-${ascent_version}/
ascent_install_dir=${root_dir}/install/ascent-${ascent_version}/

if ${build_ascent}; then
if [ ! -d ${ascent_src_dir} ]; then
    echo "downloading ascent tarball"
    echo "**** Cloning Ascent"
    git clone --recursive https://github.com/Alpine-DAV/ascent.git
fi

echo "**** Configuring Ascent"
cmake -S ${ascent_src_dir} -B ${ascent_build_dir} \
  -DCMAKE_VERBOSE_MAKEFILE:BOOL=${enable_verbose} \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=${ascent_install_dir} \
  -DENABLE_MPI=ON\
  -DENABLE_FORTRAN=OFF\
  -DENABLE_TESTS=ON \
  -DENABLE_PYTHON=OFF \
  -DENABLE_OPENMP=${enable_openmp}\
  -DBLT_CXX_STD=c++14 \
  -DCONDUIT_DIR=${conduit_install_dir} \
  -DENABLE_HIP=OFF \
  -DVTKH_ENABLE_FILTER_CONTOUR_TREE=OFF \
  -DENABLE_VTKH=ON \
  -DVTKM_DIR=${vtkm_install_dir} \

echo "**** Building Ascent"
cmake --build ${ascent_build_dir} -j${build_jobs}
echo "**** Installing Ascent"
cmake --install ${ascent_build_dir}

fi # build_ascent

warpx_src_dir=${root_dir}/WarpX
warpx_build_dir=${root_dir}/build/WarpX
warpx_install_dir=${root_dir}/install/WarpX

if ${build_warpx}; then
if [ ! -d "${warpx_src_dir}" ]; then
git clone --recursive https://github.com/ECP-WarpX/WarpX.git
fi

rm -rf ${warpx_build_dir}
rm -rf ${warpx_install_dir}

cmake -S ${warpx_src_dir}  -B ${warpx_build_dir} \
	-DCMAKE_INSTALL_PREFIX="${warpx_install_dir}" \
	-DCMAKE_PREFIX_PATH="${ascent_install_dir};${hdf5_install_dir}" \
	-DWarpX_ASCENT=ON -DWarpX_DIMS=3 -DWarpX_COMPUTE=OMP -DopenPMD_USE_ADIOS2=OFF -DWarpX_PSATD=OFF -DWarpX_QED=OFF -DWarpX_GPUCLOCK=OFF -DWarpX_PRECISION=SINGLE

cmake --build ${warpx_build_dir} -j${build_jobs}
cmake --install ${warpx_build_dir}
fi
