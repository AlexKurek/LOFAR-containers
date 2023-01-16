Bootstrap: docker
From: ubuntu:18.04

%environment
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/lofar/lib:/opt/casacore/lib:/opt/pybdsf/lib:/opt/dysco/lib:/opt/LOFARBeam/lib/:/opt/aoflagger/lib:/opt/intel/oneapi/mkl/latest/lib/intel64/:/opt/armadillo/lib/:/opt/EveryBeam/lib/:/usr/local/cuda-11.4/lib64/:/usr/local/cuda-11.4/targets/x86_64-linux/lib/:/opt/OpenBLAS/lib:/opt/SuperLU/lib/

	PATH=${PATH}:/opt/lofar/bin:/opt/dysco/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/aoflagger/bin:/opt/RMextract-0.4/bin:/opt/casacore/bin:/opt/pybdsf/bin:/opt/WSClean/bin:/opt/LSMTool/bin:/opt/LoSoTo/bin:/opt/aoflagger/bin

	PYTHONPATH=${PYTHONPATH}:/opt/lofar/lib/python2.7/site-packages:/opt/RMextract-0.4/lib/python2.7/site-packages:/opt/LSMTool/lib/python2.7/site-packages:/opt/LoSoTo/lib/python2.7/site-packages:/opt/pybdsf/lib/python2.7/site-packages:/opt/pybdsf/lib64/python2.7/site-packages:/opt/python-casacore/lib/python2.7/site-packages:/opt/python-casacore/lib64/python2.7/site-packages:/opt/LOFARBeam/lib/python2.7/site-packages:/opt/pyFFTW/lib/python2.7/site-packages

	AOFLAGGERROOT=/opt/aoflagger
	CASARCFILES=/opt/lofar/.casarc
	CASAROOT=/opt/casacore
	HDF5ROOT=/usr/local
	LOFARROOT=/opt/lofar
	PYRAPROOT=/opt/python-casacore
	WCSROOT=/opt/wcslib

	export LD_LIBRARY_PATH PATH PYTHONPATH
	export AOFLAGGERROOT CASARCFILES CASAROOT HDF5ROOT LOFARROOT PYRAPROOT WCSROOT




%post
	# https://svn.astron.nl/LOFAR/tags/LOFAR-Release-3_2_18/Docker/lofar-base/Dockerfile.tmpl
	# gcc -march=native -E -v - </dev/null 2>&1 | grep cc1

	export INSTALLDIR=/opt
	export DEBIAN_FRONTEND=noninteractive
	export PYTHON_VERSION=2.7

	export AOFLAGGER_VERSION=2.15.0
	export ARMADILLO_VERSION=11.0.0
	export BOOST_VERSION=1_68_0
	export BOOST_VERSIONdots=1.68.0
	export CASACORE_VERSION=2.4.1
	export CMAKE_VERSION=3.23.0
	export DP3_VERSION=4.2
	export FFTW_VERSION=3.3.10
	export GCC_VERSION_COMPATIBILITY=9 # 9.3
	export GCC_VERSION=11 # 11.1
	export HDF5_VERSION=1.8.21
	export LOFAR_BRANCH=tags/LOFAR-Release-3_2_18
	export LOFAR_BUILDVARIANT=gnucxx11_optarch
	export LOFAR_REVISION=43260
	# export MKL_VERSION=2020.4-912
	export MKL_ONEAPI_VERSION=2022.0.2
	export NUMEXPR_VERSION=2.7.3
	export NUMPY3_VERSION=1.19.5
	export PYFFTW_VERSION=d74d032
	export PYTHON_CASACORE_VERSION=2.1.2
	export RMEXTRACT_VERSION=0.4
	export WCSLIB_VERSION=7.9
	# export EVERYBEAM_VERSION=0.2.0
	# export WSCLEAN_VERSION=3.0

	export J=27

	export CMAKE_ROOT=/usr/local/share/cmake-3.23
	export FFLAGS=-fPIC
	export LD_LIBRARY_PATH=/opt/casacore/lib/:/opt/wcslib/lib/:/opt/dysco/lib
	export PATH=${PATH}:/opt/casacore/bin/:/opt/dysco/bin
	export PYTHONPATH=/opt/python-casacore/lib/python2.7/site-packages:/opt/python-casacore/lib64/python2.7/site-packages:/opt/LoSoTo/lib/python2.7/site-packages:/opt/LSMTool/lib/python2.7/site-packages:/opt/RMextract-0.4/lib/python2.7/site-packages

	echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
	sed -i 's/requiretty/!requiretty/g' /etc/sudoers



	## Base and runtime dependencies
	apt-get update -qq
	apt-get install -y -qq apt-utils wget mc libcfitsio-bin python-pip cython pkg-config # libopenblas-base
	#pip install -q numpy # https://software.intel.com/content/www/us/en/develop/articles/numpyscipy-with-intel-mkl.html
	pip install -q pyfits pywcs python-monetdb
	pip install -q configparser
	pip install -q wcsaxes
	pip install -q xmlrunner
	pip install -q APLpy==1.1.1




	# *****************************
	#   CUDA
	# *****************************

	# https://sylabs.io/guides/3.7/user-guide/gpu.html
	# checks driver version: nvidia-smi
	# install driver: ubuntu-drivers autoinstall && apt install nvidia-driver-450 && shutdown -r now # https://www.linuxbabe.com/ubuntu/install-nvidia-driver-ubuntu-18-04
	# https://gitlab.com/astron-idg/idg/-/blob/master/Dockerfiles/ubuntu-18.04
	# sudo nvidia-uninstall
	apt-get install -y libxml2
	cd /tmp/
	rm -r -f cuda*
	wget -q --retry-connrefused https://developer.download.nvidia.com/compute/cuda/11.6.2/local_installers/cuda_11.6.2_510.47.03_linux.run
	chmod +x /tmp/cuda*
	/tmp/cuda* --silent --toolkit
	rm -f cuda_11.6.2_510.47.03_linux.run

	ln -s /usr/local/cuda-11.6/targets/x86_64-linux/lib/stubs/libcuda.so /usr/lib/libcuda.so.1 # https://github.com/tensorflow/tensorflow/issues/4078
	# nvidia-smi -l 2
	# nvidia-smi --query-gpu=utilization.gpu --format=csv --loop=1
	export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda-11.6/lib64/:/usr/local/cuda-11.6/targets/x86_64-linux/lib/stubs/


	# *****************************
	#   gcc, g++ i gfortran - compatibility
	# *****************************
	
	apt-get install -y -qq gfortran

	apt-get install -y -qq software-properties-common
	echo -ne "\n \n"| add-apt-repository ppa:ubuntu-toolchain-r/test
	apt-get update -qq
	apt-get install -y gcc-${GCC_VERSION_COMPATIBILITY} g++-${GCC_VERSION_COMPATIBILITY} gfortran-${GCC_VERSION_COMPATIBILITY}

	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 30 --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-7 --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-7 --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-7
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION_COMPATIBILITY} 40 --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-${GCC_VERSION_COMPATIBILITY} --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-${GCC_VERSION_COMPATIBILITY} --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-${GCC_VERSION_COMPATIBILITY}
	#bash -c "2 | update-alternatives --config gcc"
	gcc -v

	update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 30
	update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION_COMPATIBILITY} 40
	update-alternatives --set c++ /usr/bin/g++
	#bash -c "0 | update-alternatives --config g++"
	g++ -v

	update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-7 40
	update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-${GCC_VERSION_COMPATIBILITY} 60
	#bash -c "0 | update-alternatives --config gfortran"
	gfortran -v


	# *****************************
	#   gcc, g++ i gfortran
	# *****************************

	apt-get install -y gcc-${GCC_VERSION} g++-${GCC_VERSION} gfortran-${GCC_VERSION}

	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 50 --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-${GCC_VERSION} --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-${GCC_VERSION} --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-${GCC_VERSION}

	update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 50
	update-alternatives --set c++ /usr/bin/g++

	update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-${GCC_VERSION} 70


	# *****************************
	#   OpenBLAS
	# *****************************

	apt-get install -y -qq git
	mkdir -p ${INSTALLDIR}/OpenBLAS/
	cd ${INSTALLDIR}/OpenBLAS/
	git clone https://github.com/xianyi/OpenBLAS.git src/
	# cd src/
	#git checkout ${OPENBLAS_VERSION}
	cd ${INSTALLDIR}/OpenBLAS/src/
	make -j ${J}
	make install PREFIX=${INSTALLDIR}/OpenBLAS USE_OPENMP=0 NUM_THREADS=56 TARGET=SKYLAKEX
	cd ../..
	rm -rf ${INSTALLDIR}/OpenBLAS/src/
	export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALLDIR}/OpenBLAS/lib/


	# *****************************
	#   MKL
	# *****************************

	# apt-cache policy intel-mkl-64bit-202*
	# http://dirk.eddelbuettel.com/blog/2018/04/15/
	# cd /tmp/
	# wget -q --retry-connrefused https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
	# apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
	# rm GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
	# sh -c 'echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list'
	# apt-get update
	# apt-get install -y intel-mkl-64bit-${MKL_VERSION}
	# update-alternatives --install /usr/lib/x86_64-linux-gnu/libblas.so libblas.so-x86_64-linux-gnu /opt/intel/mkl/lib/intel64/libmkl_rt.so 50
	# update-alternatives --install /usr/lib/x86_64-linux-gnu/libblas.so.3 libblas.so.3-x86_64-linux-gnu /opt/intel/mkl/lib/intel64/libmkl_rt.so 50
	# update-alternatives --install /usr/lib/x86_64-linux-gnu/liblapack.so liblapack.so-x86_64-linux-gnu /opt/intel/mkl/lib/intel64/libmkl_rt.so 50
	# update-alternatives --install /usr/lib/x86_64-linux-gnu/liblapack.so.3 liblapack.so.3-x86_64-linux-gnu /opt/intel/mkl/lib/intel64/libmkl_rt.so 50
	# echo "/opt/intel/lib/intel64"     >  /etc/ld.so.conf.d/mkl.conf
	# echo "/opt/intel/mkl/lib/intel64" >> /etc/ld.so.conf.d/mkl.conf
	# ldconfig
	# export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALLDIR}/intel/mkl/lib/intel64_lin

	# MKL is detected (usually through BLAS) by:
	# superlu
	# armadillo
	# casacore
	# aoflagger
	# lofarsoft
	# lofarbeam
	# idg
	# everybeam
	# dp3
	# wsclean
	# numpy, scipy, numexpr


	# *****************************
	#   MKL oneAPI
	# *****************************

	# https://software.intel.com/content/www/us/en/develop/documentation/installation-guide-for-intel-oneapi-toolkits-linux/top/installation/install-using-package-managers/apt.html
	# /opt/intel/oneapi/mkl/latest/include

	cd /tmp/
	wget -q --retry-connrefused https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
	apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
	rm GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
	sh -c 'echo deb https://apt.repos.intel.com/oneapi all main > /etc/apt/sources.list.d/oneAPI.list'
	# add-apt-repository "deb https://apt.repos.intel.com/oneapi all main"
	apt-get update
	# apt-get install -y intel-oneapi-mkl-${MKL_ONEAPI_VERSION}
	apt-get install -y intel-oneapi-mkl-devel

	update-alternatives --install /usr/lib/x86_64-linux-gnu/libblas.so libblas.so-x86_64-linux-gnu /opt/intel/oneapi/mkl/${MKL_ONEAPI_VERSION}/lib/intel64/libmkl_rt.so 50
	update-alternatives --install /usr/lib/x86_64-linux-gnu/libblas.so.3 libblas.so.3-x86_64-linux-gnu /opt/intel/oneapi/mkl/${MKL_ONEAPI_VERSION}/lib/intel64/libmkl_rt.so 50
	update-alternatives --install /usr/lib/x86_64-linux-gnu/liblapack.so liblapack.so-x86_64-linux-gnu /opt/intel/oneapi/mkl/${MKL_ONEAPI_VERSION}/lib/intel64/libmkl_rt.so 50
	update-alternatives --install /usr/lib/x86_64-linux-gnu/liblapack.so.3 liblapack.so.3-x86_64-linux-gnu /opt/intel/oneapi/mkl/${MKL_ONEAPI_VERSION}/lib/intel64/libmkl_rt.so 50
	echo "/opt/intel/oneapi/mkl/latest/lib/intel64" >> /etc/ld.so.conf.d/mkl.conf
	echo "MKL_THREADING_LAYER=GNU" >> /etc/environment
	ldconfig

	export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALLDIR}/intel/oneapi/mkl/${MKL_ONEAPI_VERSION}/lib/intel64/
	bash -c "source ${INSTALLDIR}/intel/oneapi/mkl/latest/env/vars.sh"
	bash -c "source ${INSTALLDIR}/intel/oneapi/compiler/latest/env/vars.sh"

	
	# *****************************
	#   Numpy, Scipy @ MKL oneAPI
	# *****************************

	update-alternatives --set gcc "/usr/bin/gcc-${GCC_VERSION_COMPATIBILITY}"
	update-alternatives --set g++ "/usr/bin/g++-${GCC_VERSION_COMPATIBILITY}"
	update-alternatives --set gfortran "/usr/bin/gfortran-${GCC_VERSION_COMPATIBILITY}"

	# https://medium.com/@black_swan/using-mkl-to-boost-numpy-performance-on-ubuntu-f62781e63c38
	# https://software.intel.com/content/www/us/en/develop/articles/numpyscipy-with-intel-mkl.html

	# Python 2.7 Numpy
	cd /tmp/
	wget -q --retry-connrefused https://github.com/numpy/numpy/archive/v1.16.6.tar.gz
	tar xzf v1.16.6.tar.gz
	rm -f v1.16.6.tar.gz
	cd numpy-1.16.6/
	cp site.cfg.example site.cfg
	echo "[mkl]" >> site.cfg
	echo "library_dirs = /opt/intel/oneapi/mkl/latest/lib/intel64" >> site.cfg
	echo "include_dirs = /opt/intel/oneapi/mkl/latest/include" >> site.cfg
	echo "mkl_libs = mkl_rt" >> site.cfg
	echo "lapack_libs =" >> site.cfg
	python setup.py config build_clib build_ext install
	cd ..
	python -c "import numpy as np;np.__config__.show()"
	rm -rf numpy-1.16.6/

	# Python 2.7 SciPy
	wget -q --retry-connrefused https://github.com/scipy/scipy/archive/v1.2.3.tar.gz
	tar xzf v1.2.3.tar.gz
	rm -f v1.2.3.tar.gz
	cd scipy-1.2.3/
	python setup.py config build_clib build_ext install
	cd ..
	python -c "import scipy as sp;sp.__config__.show()"
	rm -rf scipy-1.2.3/

	# Python 3.6 Numpy
	apt-get install -y -qq python3-pip
	pip3 install cython
	wget -q --retry-connrefused https://github.com/numpy/numpy/archive/v${NUMPY3_VERSION}.tar.gz
	tar xzf v${NUMPY3_VERSION}.tar.gz
	rm -f v${NUMPY3_VERSION}.tar.gz
	cd numpy-${NUMPY3_VERSION}/
	cp site.cfg.example site.cfg
	echo "[mkl]" >> site.cfg
	echo "library_dirs = /opt/intel/oneapi/mkl/latest/lib/intel64" >> site.cfg
	echo "include_dirs = /opt/intel/oneapi/mkl/latest/include" >> site.cfg
	echo "mkl_libs = mkl_rt" >> site.cfg
	echo "lapack_libs =" >> site.cfg
	python3 setup.py config build_clib build_ext install
	cd ..
	python3 -c "import numpy as np;np.__config__.show()"
	rm -rf numpy-${NUMPY3_VERSION}/

	update-alternatives --set gcc "/usr/bin/gcc-${GCC_VERSION}"
	update-alternatives --set g++ "/usr/bin/g++-${GCC_VERSION}"
	update-alternatives --set gfortran "/usr/bin/gfortran-${GCC_VERSION}"


	# *****************************
	#   Boost
	# *****************************

	apt-get install -y -qq build-essential python-dev python3-dev # python3-pip
	#pip3 install -q numpy
	mkdir -p ${INSTALLDIR}/Boost/build/
	cd ${INSTALLDIR}/Boost/build/
	wget -q --retry-connrefused https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSIONdots}/source/boost_${BOOST_VERSION}.tar.gz
	tar xzf boost_${BOOST_VERSION}.tar.gz
	rm boost_${BOOST_VERSION}.tar.gz
	cd boost_${BOOST_VERSION}/

	# https://stackoverflow.com/questions/28830653/build-boost-with-multiple-python-versions
	./bootstrap.sh --with-python=/usr/bin/python2
	./b2 install --with-python -j ${J}

	./bootstrap.sh --with-python=/usr/bin/python3 --with-python-root=/usr
	./b2 --with-python --clean
	./b2 install --with-python -j ${J}

	./bootstrap.sh --without-libraries=chrono,container,context,contract,coroutine,exception,fiber,graph,graph_parallel,locale,log,math,mpi,random,serialization,stacktrace,type_erasure,wave
	./b2 --with-python --clean
	./b2 install -j ${J}

	# dla Casacore:
	ln /usr/local/lib/libboost_python27.so.${BOOST_VERSIONdots} /usr/local/lib/libboost_python.so
	ln /usr/local/lib/libboost_python27.so.${BOOST_VERSIONdots} /usr/local/lib/libboost_python-py27.so

	# dla AOFlaggera 2.15:
	ln /usr/local/lib/libboost_python36.so.${BOOST_VERSIONdots} /usr/local/lib/libboost_python3.so
	ln /usr/local/lib/libboost_numpy36.so.${BOOST_VERSIONdots} /usr/local/lib/libboost_numpy3.so

	# dla LOFAR Beam:
	ln /usr/local/lib/libboost_numpy27.so.${BOOST_VERSIONdots} /usr/local/lib/libboost_numpy.so

	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/Boost/build/"


	# *****************************
	#   HDF5
	# *****************************

	mkdir -p ${INSTALLDIR}/HDF5/build/
	cd ${INSTALLDIR}/HDF5/build/
	wget -q --retry-connrefused https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz
	tar xzf hdf5-${HDF5_VERSION}.tar.gz
	rm hdf5-${HDF5_VERSION}.tar.gz
	cd hdf5-${HDF5_VERSION}/
	./configure --prefix=/usr/local/ --enable-cxx --enable-silent-rules #> /dev/null
	make -j ${J} > /dev/null
	make install > /dev/null
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/HDF5/build/"


	# *****************************
	# WCSlib (with pgsbox)
	# *****************************

	apt-get install -y -qq libcfitsio-dev fort77 flex
	mkdir -p ${INSTALLDIR}/wcslib/build/
	cd ${INSTALLDIR}/wcslib/build/
	wget -q --retry-connrefused ftp://ftp.atnf.csiro.au/pub/software/wcslib/wcslib-${WCSLIB_VERSION}.tar.bz2
	tar -xjf wcslib-${WCSLIB_VERSION}.tar.bz2
	rm wcslib-${WCSLIB_VERSION}.tar.bz2
	cd wcslib-${WCSLIB_VERSION}
	./configure --prefix=${INSTALLDIR}/wcslib/ --without-pgplot
	make -j ${J}
	make install
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/wcslib/build/"


	# *****************************
	#   FFTW
	# *****************************

	mkdir -p ${INSTALLDIR}/FFTW/build/
	cd ${INSTALLDIR}/FFTW/build/
	wget -q --retry-connrefused "http://www.fftw.org/fftw-${FFTW_VERSION}.tar.gz"
	tar xzf fftw-${FFTW_VERSION}.tar.gz
	rm -rf fftw-${FFTW_VERSION}.tar.gz
	cd fftw-${FFTW_VERSION}

	# double precision
	./configure --prefix=/usr/ --disable-doc --enable-silent-rules --enable-shared --enable-threads --enable-sse2 --enable-avx --enable-avx2 --enable-avx512 > /dev/null
	make -j${J} > /dev/null
	make install > /dev/null

	# single precision
	make clean > /dev/null
	./configure --prefix=/usr/ --disable-doc --enable-silent-rules --enable-shared --enable-threads --enable-sse2 --enable-avx --enable-avx2 --enable-avx512 --enable-float > /dev/null
	make -j${J} > /dev/null
	make install > /dev/null

	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/FFTW/build/"


	# *****************************
	#   pyFFTW
	# *****************************

	mkdir -p ${INSTALLDIR}/pyFFTW/build/
	cd ${INSTALLDIR}/pyFFTW/build/
	git clone https://github.com/pyFFTW/pyFFTW.git source/
	cd source/
	git checkout ${PYFFTW_VERSION}
	mkdir -p ${INSTALLDIR}/pyFFTW/lib/python${PYTHON_VERSION}/site-packages/
	export PYTHONPATH=${PYTHONPATH}:/opt/pyFFTW/lib/python2.7/site-packages
	python ./setup.py install --prefix=${INSTALLDIR}/pyFFTW/
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/pyFFTW/{build,source}/"


	# *****************************
	#   PyBDSF
	# *****************************

	update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-7 70 # https://github.com/lofar-astron/PyBDSF/issues/135
	apt-get install -y -qq git python-pyfits python-matplotlib
	pip install -q setuptools
	pip install -q decorator==4.4.2
	pip install -q ipython # 5.10.0
	pip install -q astropy # 2.0.16
	# pip install -q pyFFTW  # 0.12.0
	pip install git+https://github.com/lofar-astron/PyBDSF.git
	# pip install --upgrade --force-reinstall git+https://github.com/lofar-astron/PyBDSF.git
	update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-${GCC_VERSION} 80


	# *****************************
	#   cmake
	# *****************************

	apt-get install -y -qq libssl-dev libncurses5-dev libncursesw5-dev libmd0
	mkdir -p ${INSTALLDIR}/cmake/build/
	cd ${INSTALLDIR}/cmake/build/
	wget -q --retry-connrefused "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz"
	tar xzf cmake-${CMAKE_VERSION}.tar.gz
	rm cmake-${CMAKE_VERSION}.tar.gz
	cd cmake-${CMAKE_VERSION}
	CC=cc CXX=CC
	./bootstrap --parallel=${J} -- -DCMAKE_BUILD_TYPE:STRING=Release > /dev/null
	make -j ${J} > /dev/null
	make install > /dev/null
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/cmake/build/"
	hash -r


	# *****************************
	#   SuperLU
	# *****************************

	mkdir -p ${INSTALLDIR}/SuperLU/build/
	cd ${INSTALLDIR}/SuperLU/
	git clone https://github.com/xiaoyeli/superlu.git src/
	cd src/
	#git checkout $SUPERLU_VERSION
	cd ${INSTALLDIR}/SuperLU/build/
	cmake ../src -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/SuperLU -DUSE_XSDK_DEFAULTS=TRUE -Denable_blaslib=OFF -DBLAS_LIBRARY=${INSTALLDIR}/OpenBLAS/lib/libopenblas.so -DCMAKE_CXX_FLAGS="-O3 -march=native -DNDEBUG" -Denable_tests=OFF -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release
	make -j ${J}
	make install
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/SuperLU/{build,src}"
	export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALLDIR}/SuperLU/lib/


	# *****************************
	#   Armadillo
	# *****************************

	apt-get install -y -q libarpack2-dev libatlas-base-dev # libopenblas-dev libsuperlu-dev libsuperlu5
	mkdir -p ${INSTALLDIR}/armadillo/
	cd ${INSTALLDIR}/armadillo/
	wget -q --retry-connrefused "http://sourceforge.net/projects/arma/files/armadillo-${ARMADILLO_VERSION}.tar.xz"
	tar xf armadillo-${ARMADILLO_VERSION}.tar.xz
	rm armadillo-${ARMADILLO_VERSION}.tar.xz
	cd armadillo-${ARMADILLO_VERSION}/
	cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/armadillo/ -Wno-dev -DCMAKE_CXX_FLAGS="-O3 -march=native -DNDEBUG" -DSuperLU_INCLUDE_DIR=${INSTALLDIR}/SuperLU/include/ -DSuperLU_LIBRARY=${INSTALLDIR}/SuperLU/lib/libsuperlu.so -DCMAKE_PREFIX_PATH="${INSTALLDIR}/OpenBLAS/;/opt/intel/oneapi/mkl/latest/lib/intel64/" .
	make -j ${J}
	make install > /dev/null
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/armadillo/armadillo-${ARMADILLO_VERSION}/"
	export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALLDIR}/armadillo/lib


	# *****************************
	#   Casacore
	# *****************************

	update-alternatives --set gcc "/usr/bin/gcc-${GCC_VERSION_COMPATIBILITY}"
	update-alternatives --set g++ "/usr/bin/g++-${GCC_VERSION_COMPATIBILITY}"
	update-alternatives --set gfortran "/usr/bin/gfortran-${GCC_VERSION_COMPATIBILITY}"

	apt-get install -y -qq flex bison libreadline-dev libncurses5-dev libncursesw5-dev # libopenblas-dev
	mkdir -p ${INSTALLDIR}/casacore/build/
	ls ${INSTALLDIR}/casacore/
	cd ${INSTALLDIR}/casacore/
	git clone https://github.com/casacore/casacore.git src/
	if [ "${CASACORE_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/casacore/src/ && git checkout tags/v${CASACORE_VERSION}; fi
	mkdir -p ${INSTALLDIR}/casacore/data/
	cd ${INSTALLDIR}/casacore/data/
	wget -q --retry-connrefused ftp://ftp.astron.nl/outgoing/Measures/WSRT_Measures.ztar
	tar xf WSRT_Measures.ztar
	rm -f WSRT_Measures.ztar
	cd ${INSTALLDIR}/casacore/build/
	cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casacore/ -DDATA_DIR=${INSTALLDIR}/casacore/data/ -DBUILD_PYTHON=True -DENABLE_TABLELOCKING=OFF -DUSE_OPENMP=ON -DBUILD_PYTHON3=ON -DUSE_FFTW3=TRUE -DUSE_HDF5=ON -DHDF5_IS_PARALLEL=NO -DCXX11=YES -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-fsigned-char -O3 -DNDEBUG -march=native" -DWCSLIB_INCLUDE_DIR=${INSTALLDIR}/wcslib/include -DWCSLIB_LIBRARY=${INSTALLDIR}/wcslib/lib/libwcs.so -DBUILD_TESTING=OFF ../src/
	make -j ${J}
	make install
	bash -c "strip ${INSTALLDIR}/casacore/{lib,bin}/* || true"
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/casacore/{build,src}/"

	update-alternatives --set gcc "/usr/bin/gcc-${GCC_VERSION}"
	update-alternatives --set g++ "/usr/bin/g++-${GCC_VERSION}"
	update-alternatives --set gfortran "/usr/bin/gfortran-${GCC_VERSION}"


	# *****************************
	#   Python Casacore
	# *****************************

	mkdir ${INSTALLDIR}/python-casacore/
	cd ${INSTALLDIR}/python-casacore/
	git clone https://github.com/casacore/python-casacore
	if [ "$PYTHON_CASACORE_VERSION" != "latest" ]; then cd ${INSTALLDIR}/python-casacore/python-casacore/ && git checkout tags/v${PYTHON_CASACORE_VERSION}; fi
	cd ${INSTALLDIR}/python-casacore/python-casacore/
	./setup.py build_ext -I"${INSTALLDIR}/casacore/include/:${INSTALLDIR}/wcslib/include/" -L"${INSTALLDIR}/casacore/lib/:${INSTALLDIR}/wcslib/lib/"
	mkdir -p ${INSTALLDIR}/python-casacore/lib/python${PYTHON_VERSION}/site-packages/
	mkdir -p ${INSTALLDIR}/python-casacore/lib64/python${PYTHON_VERSION}/site-packages/
	cd ${INSTALLDIR}/python-casacore/python-casacore/
	./setup.py install --prefix=${INSTALLDIR}/python-casacore/
	bash -c "find ${INSTALLDIR}/python-casacore/lib/ -name '*.so' | xargs strip || true"
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/python-casacore/python-casacore/"








	# Run-time dependencies
	# slurm-client installs libhdf5-100
	apt-get install -y -qq libpng-dev libsigc++-2.0-dev libxml++2.6-2v5 libgslcblas0 openssh-client gettext-base rsync # slurm-client # ipython libxml2


	# *****************************
	#   AOFlagger
	# *****************************

	update-alternatives --set gcc "/usr/bin/gcc-${GCC_VERSION_COMPATIBILITY}"
	update-alternatives --set g++ "/usr/bin/g++-${GCC_VERSION_COMPATIBILITY}"
	update-alternatives --set gfortran "/usr/bin/gfortran-${GCC_VERSION_COMPATIBILITY}"

	# Run-time dependencies
	apt-get install -y -qq --no-install-recommends libxml++2.6-2v5 libpng-tools libpython2.7
	apt-get install -y -qq git g++ libxml++2.6-dev libpng-dev liblua5.3-dev graphviz libgsl-dev # libopenblas-dev doxygen
	#apt-get install -y -qq --no-install-recommends libgtkmm-3.0-dev
	mkdir -p ${INSTALLDIR}/aoflagger/build/
	cd ${INSTALLDIR}/aoflagger/
	
	# 2.15
	wget --retry-connrefused "https://sourceforge.net/projects/aoflagger/files/aoflagger-${AOFLAGGER_VERSION}/aoflagger-${AOFLAGGER_VERSION}.tar.bz2"
	tar xf aoflagger-${AOFLAGGER_VERSION}.tar.bz2
	rm aoflagger-${AOFLAGGER_VERSION}.tar.bz2
	cd ${INSTALLDIR}/aoflagger/build
	cmake -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/ -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_FLAGS="--std=c++11 -D_GLIBCXX_USE_CXX11_ABI=1 -O3 -march=native -DNDEBUG" -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/aoflagger ../aoflagger-2.15/
	
	# 3.1
	#apt-get install -y -qq pybind11-dev
	#git clone https://gitlab.com/aroffringa/aoflagger.git src/
	#cd src/
	#git checkout tags/v${AOFLAGGER_VERSION}
	#cd ../build/
	#cmake -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/ -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_FLAGS="--std=c++11 -W -Woverloaded-virtual -Wno-unknown-pragmas -D_GLIBCXX_USE_CXX11_ABI=1 -O3 -march=native -DNDEBUG" -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/aoflagger/ ../src/
	
	make -j ${J}
	make install
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/aoflagger/{build,aoflagger-2.15}/"
	#bash -c "rm -rf ${INSTALLDIR}/aoflagger/{build,src}/" # 3.0
	bash -c "strip ${INSTALLDIR}/aoflagger/{lib,bin}/* || true"

	update-alternatives --set gcc "/usr/bin/gcc-${GCC_VERSION}"
	update-alternatives --set g++ "/usr/bin/g++-${GCC_VERSION}"
	update-alternatives --set gfortran "/usr/bin/gfortran-${GCC_VERSION}"


	# *****************************
	#   DYSCO
	# *****************************

	#apt-get install -y -qq libgsl-dev
	mkdir ${INSTALLDIR}/dysco/
	cd ${INSTALLDIR}/dysco/
	git clone https://github.com/aroffringa/dysco
	cd ${INSTALLDIR}/dysco/dysco/
	mkdir build/
	cd build/
	cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/dysco/ -DCMAKE_CXX_FLAGS="--std=c++11 -O3 -DNDEBUG -march=native" -DCMAKE_BUILD_TYPE=Release -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/ ../
	make -j ${J}
	make install
	cd ../..
	cp ${INSTALLDIR}/dysco/dysco/build/decompress ${INSTALLDIR}/dysco/bin/decompress # https://github.com/aroffringa/dysco/issues/12#issuecomment-773134161
	bash -c "rm -rf ${INSTALLDIR}/dysco/dysco/"


	# *****************************
	#   LOFAR
	# *****************************

	apt-get install -y -qq --no-install-recommends subversion bison flex blitz++ python-dev libxml2-dev libpng-dev libunittest++-dev libxml++2.6-dev binutils-dev # libopenblas-dev libhdf5-dev
	apt-get install -y -qq python-psycopg2 libpqxx-dev python-qpid # libarmadillo-dev gfortran
	mkdir -p ${INSTALLDIR}/lofar/build/${LOFAR_BUILDVARIANT}/
	cd ${INSTALLDIR}/lofar/
	svn --non-interactive -q co -r ${LOFAR_REVISION} -N https://svn.astron.nl/LOFAR/${LOFAR_BRANCH} src/
	svn --non-interactive -q up src/CMake/
	cd ${INSTALLDIR}/lofar/build/${LOFAR_BUILDVARIANT}/
	cmake -DCMAKE_PREFIX_PATH="${INSTALLDIR}/armadillo/" -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/ -DAOFLAGGER_ROOT_DIR=${INSTALLDIR}/aoflagger/ -DUSE_OPENMP=True -DBUILD_PACKAGES="Pipeline MS" -DUSE_LOG4CPLUS=OFF -DCMAKE_CXX_FLAGS="-O3 -march=native -DNDEBUG" -Wno-dev ${INSTALLDIR}/lofar/src/ # -DBUILD_PACKAGES="ParmDB pyparmdb Pipeline MS"
	make -j ${J}
	#sed -i '29,31d' include/ApplCommon/PosixTime.h

	make install
	bash -c "mkdir -p ${INSTALLDIR}/lofar/var/{log,run}"
	bash -c "chmod a+rwx  ${INSTALLDIR}/lofar/var/{log,run}"
	bash -c "strip ${INSTALLDIR}/lofar/bin/* || true" > /dev/null
	bash -c "rm -rf ${INSTALLDIR}/lofar/{build,src}"


	# *****************************
	#   LOFAR Beam
	# *****************************

	mkdir -p ${INSTALLDIR}/LOFARBeam/build/
	cd ${INSTALLDIR}/LOFARBeam/build/
	git clone https://github.com/lofar-astron/LOFARBeam.git src/
	cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/LOFARBeam/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/ -DCMAKE_CXX_FLAGS="-O3 -march=native -DNDEBUG" -DCMAKE_BUILD_TYPE=Release src/
	make -j ${J}
	make install
	bash -c "rm -rf ${INSTALLDIR}/LOFARBeam/{build,src}/"
	export PYTHONPATH=${PYTHONPATH}:${INSTALLDIR}/LOFARBeam/lib/python2.7/site-packages


	# *****************************
	#   IDG
	# *****************************

	mkdir -p ${INSTALLDIR}/IDG/build/
	cd ${INSTALLDIR}/IDG/build/
	git clone https://gitlab.com/astron-idg/idg.git src/
	cmake -DCMAKE_PREFIX_PATH="/usr/local/cuda-11.4/lib64/" -DCMAKE_INSTALL_PREFIX=/usr/ -Wno-dev -DCMAKE_CXX_FLAGS="-O3 -march=native -DNDEBUG" -DCMAKE_BUILD_TYPE=Release -DBUILD_WITH_MKL=ON -DBUILD_LIB_CUDA=ON src/
	make -j ${J}
	make install
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/IDG/{build,src}/"


	# *****************************
	#   EveryBeam
	# *****************************

	mkdir -p ${INSTALLDIR}/EveryBeam/build/
	cd ${INSTALLDIR}/EveryBeam/build/
	git clone https://git.astron.nl/RD/EveryBeam.git src/
	# cd src/
	# git checkout tags/v${EVERYBEAM_VERSION}
	# cd ..
	cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/EveryBeam/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/ -DCMAKE_CXX_FLAGS="-O3 -march=native -DNDEBUG" -DCMAKE_BUILD_TYPE=Release src/
	make -j ${J}
	make install
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/EveryBeam/{build,src}/"
	bash -c "strip ${INSTALLDIR}/EveryBeam/lib/* || true"
	export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALLDIR}/EveryBeam/lib/

	
	# *****************************
	#   DP3
	# *****************************

	apt-get install -y -qq --no-install-recommends python3-dev # libarmadillo-dev python3-numpy
	mkdir -p ${INSTALLDIR}/lofar/build/
	cd ${INSTALLDIR}/lofar/
	rm -rf src/
	git clone https://github.com/lofar-astron/DP3.git src/
	cd src/
	git checkout tags/v${DP3_VERSION}
	#git checkout ${DP3_VERSION}
	cd ../build/
	cmake -DCMAKE_PREFIX_PATH="${INSTALLDIR}/lofar/;${INSTALLDIR}/armadillo/;${INSTALLDIR}/aoflagger/;${INSTALLDIR}/LOFARBeam/;/opt/intel/oneapi/mkl/latest/lib/intel64/" -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -Wno-dev -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/ -DCMAKE_CXX_FLAGS="-O3 -march=native -DNDEBUG" ${INSTALLDIR}/lofar/src/
	make -j ${J}
	make install
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/lofar/{build,src,CMakeFiles}"
	bash -c "strip ${INSTALLDIR}/lofar/bin/* || true" > /dev/null

	ln -s ${INSTALLDIR}/lofar/bin/DPPP ${INSTALLDIR}/lofar/bin/NDPPP
	#ln -s ${INSTALLDIR}/DPPP/bin/makesourcedb ${INSTALLDIR}/lofar/bin/makesourcedb





	# z: https://www.astron.nl/lofarwiki/doku.php?id=public:user_software:ubuntu_14_4


	# ***********************
	#   NumExpr
	# ***********************

	# for tables
	mkdir -p ${INSTALLDIR}/NumExpr/build/
	cd ${INSTALLDIR}/NumExpr/build/
	git clone -b v${NUMEXPR_VERSION} https://github.com/pydata/numexpr.git source/
	cd source/
	# https://github.com/pydata/numexpr#enable-intel-mkl-support
	touch site.cfg
	echo "[mkl]" >> site.cfg
	echo "library_dirs = /opt/intel/oneapi/mkl/latest/lib/intel64" >> site.cfg
	echo "include_dirs = /opt/intel/oneapi/mkl/latest/include" >> site.cfg
	echo "mkl_libs = mkl_rt" >> site.cfg
	python setup.py build install
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/NumExpr/{build,source}/"


	# ***********************
	#   LoSoTo
	# ***********************

	# https://github.com/lofar-astron/prefactor/issues/273#issuecomment-668551578
	# pip install tables==3.5.2
	pip install tables
	mkdir -p ${INSTALLDIR}/LoSoTo/build/
	cd ${INSTALLDIR}/LoSoTo/build/
	git clone https://github.com/revoltek/losoto.git source/
	cd source/
	git checkout c8fbd61 # https://github.com/revoltek/losoto/issues/103
	mkdir -p ${INSTALLDIR}/LoSoTo/lib/python${PYTHON_VERSION}/site-packages/
	python ./setup.py install --prefix=${INSTALLDIR}/LoSoTo/
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/LoSoTo/{build,source}/"


	# *****************************
	#   WSClean
	# *****************************

	mkdir -p ${INSTALLDIR}/WSClean/build/
	cd ${INSTALLDIR}/WSClean/
	git clone https://gitlab.com/aroffringa/wsclean.git src/
	cd src/
	# git checkout tags/v${WSCLEAN_VERSION}
	cd ../build/
	cmake -DCMAKE_PREFIX_PATH="${INSTALLDIR}/EveryBeam/;/usr/local/idg/;/opt/intel/oneapi/mkl/latest/lib/intel64/" -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/WSClean/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/ -DCMAKE_CXX_FLAGS="-O3 -march=native -DNDEBUG" -DCMAKE_BUILD_TYPE=Release -DMPI_CXX_SKIP_MPICXX=ON -Wno-dev ${INSTALLDIR}/WSClean/src/
	make -j${J}
	make install
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/WSClean/{build,src}/"
	bash -c "strip ${INSTALLDIR}/WSClean/{bin,lib}/* || true"


	# *****************************
	#   LSMTool
	# *****************************

	pip install pytest-runner==5.2
	mkdir -p ${INSTALLDIR}/LSMTool/build/
	cd ${INSTALLDIR}/LSMTool/build/
	git clone https://github.com/darafferty/LSMTool.git source/
	cd source/
	mkdir -p ${INSTALLDIR}/LSMTool/lib/python${PYTHON_VERSION}/site-packages/
	python ./setup.py install --prefix=${INSTALLDIR}/LSMTool/
	bash -c "rm -rf ${INSTALLDIR}/LSMTool/{build,source}/"


	# *****************************
	#   RMextract
	# *****************************

	mkdir -p ${INSTALLDIR}/RMextract-${RMEXTRACT_VERSION}/build/
	cd ${INSTALLDIR}/RMextract-${RMEXTRACT_VERSION}/build/
	git clone https://github.com/maaijke/RMextract.git source/
	cd source/
	mkdir -p ${INSTALLDIR}/RMextract-${RMEXTRACT_VERSION}/lib/python${PYTHON_VERSION}/site-packages/
	python ./setup.py build --add-lofar-utils
	python ./setup.py install --add-lofar-utils --prefix=${INSTALLDIR}/RMextract-${RMEXTRACT_VERSION}/
	cd ../..
	bash -c "rm -rf ${INSTALLDIR}/RMextract-${RMEXTRACT_VERSION}/build/"



	pip3 list --format=columns
	
	apt-get purge -y -qq apt-utils graphviz doxygen build-essential python-all-dev git
	apt-get purge -y -qq subversion gfortran bison flex libblitz0-dev python-pip python3-pip pkg-config
	#apt-get purge -y -qq gcc-${GCC_VERSION_COMPATIBILITY} g++-${GCC_VERSION_COMPATIBILITY} gfortran-${GCC_VERSION_COMPATIBILITY} fort77 software-properties-common
	apt-get purge -y -qq libssl-dev libncurses5-dev libncursesw5-dev libmd0
	apt-get purge -y -qq libsuperlu-dev unattended-upgrades* distro-info-data* python3-software-properties* make*
	#apt-get purge -y -qq cpp-9* cron* dirmngr*  dpkg-dev* f2c* fakeroot* gfortran-7* gir1.2-glib-2.0* gir1.2-harfbuzz-0.0* git-man* gnupg* gnupg-l10n* gnupg-utils* gpg* gpg-agent* gpg-wks-client* gpg-wks-server* gpgconf* gpgsm* icu-devtools* intel-comp-l-all-vars-19.1.1-217* iso-codes* less* libalgorithm-diff-perl* libalgorithm-diff-xs-perl* libalgorithm-merge-perl* libann0* libapr1* libaprutil1* libapt-inst2.0* libasan5* libassuan0* libbison-dev* libcdt5* libcgraph6* libclang1-6.0* libdpkg-perl* libelf1* liberror-perl* libf2c2* libf2c2-dev* libfakeroot* libfile-fcntllock-perl* libfl2* libgcc-10-dev* libgd3* libgfortran-7-dev* libgfortran-10-dev* libgfortran5* libgirepository-1.0-1* libglib2.0-bin* libglib2.0-dev-bin* libgraphite2-dev* libgts-0.7-5* libgts-bin* libgvc6* libgvpr2* libharfbuzz-gobject0* libharfbuzz-icu0* libicu-le-hb0* libiculx60* libksba8* liblab-gamut1* libllvm6.0* liblocale-gettext-perl* libnpth0* libpathplan4* libpcre16-3* libpcre3-dev* libpcre32-3* libpcrecpp0v5* libpq-dev* libpqxx-4.0v5* libpython-all-dev* libserf-1-1* libsigsegv2* libstdc++-9-dev* libsvn1* libubsan1* libxapian30* libxaw7* libxmu6* libxpm4* lsb-release* m4* patch* pinentry-curses* powermgmt-base* python-all* python-apt-common* python-asn1crypto* python-cffi-backend* python-crypto* python-cryptography* python-dbus* python-gi* python-idna* python-ipaddress* python-keyring* python-keyrings.alt* python-pip-whl* python-secretstorage* python-wheel* python-xdg* python3-apt* python3-asn1crypto* python3-cffi-backend* python3-crypto* python3-cryptography* python3-dbus* python3-gi* python3-idna* python3-keyring* python3-keyrings.alt* python3-pkg-resources* python3-secretstorage* python3-setuptools* python3-six*  python3-wheel* python3-xdg*
	#apt-get autoremove -y --purge !(intel-*)
	apt-get purge -y -qq gcc-${GCC_VERSION} g++-${GCC_VERSION} gfortran-${GCC_VERSION}


	rm -rf /usr/local/share/cmake-3.23/
	rm -rf /var/lib/apt/lists/*
	# rm -rf /usr/local/cuda-11.4/
	rm -rf /usr/lib/gcc/
	rm -f /usr/local/bin/ccmake
	rm -f /usr/local/bin/cmake

	
	echo "export HDF5_USE_FILE_LOCKING=FALSE" >> $SINGULARITY_ENVIRONMENT # https://github.com/lofar-astron/prefactor/issues/273#issuecomment-655576650
	
	touch /opt/lofar/.casarc
	echo "measures.directory: /opt/casacore/data" >> /opt/lofar/.casarc



%labels
	Author: akurek ( at ) nac.oa.uj.edu.pl (PL611 station)


%help
	This container has everything one needs to run Prefactor 3.2. It is optimised for speed and ease of use.

