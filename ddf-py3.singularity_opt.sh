Bootstrap: docker
From: debian:bullseye


%environment
   export SRC=/usr/local/src
   . $SRC/ddf-pipeline/init.sh
   export DDF_PIPELINE_CATALOGS=$SRC/catalogs/
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/:/usr/local/idg/lib/

# %files
   # /home/akurek/ddf-pipeline-mod/ /home/akurek/ddf-pipeline/

%post
   export DEBIAN_FRONTEND=noninteractive
   export J=16
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/:/usr/local/idg/lib/

   echo "Here we are installing software and other dependencies for the container!"
   apt-get update
   apt-get install -y mc \
    git \
    wget \
    rsync \
    python3-pip \
    libfftw3-dev \
    libfreetype6-dev \
    libpng-dev \
    pkg-config \
    python3-dev \
    libboost-all-dev \
    libcfitsio-dev \
    wcslib-dev \
    libatlas-base-dev \
    liblapack-dev \
    python3-tk \
    libreadline6-dev \
    liblog4cplus-dev \
    libhdf5-dev \
    libncurses5-dev \
    libssl-dev \
    flex \
    bison \
    libbison-dev \
    python3-matplotlib \
    python3-numexpr \
    python3-astropy \
    python3-cpuinfo \
    python3-future \
    python3-lxml \
    python3-pandas \
    python3-psutil \
    python3-pyfftw python3-pymysql python3-scipy \
    python3-requests python3-deap \
    python3-sshtunnel \
    python3-ruamel.yaml python3-ephem \
    ipython3 \
    libgsl-dev \
    libgtkmm-3.0-dev \
    libcfitsio-bin libxml2-dev libarmadillo-dev libsigc++-2.0-dev liblua5.3-dev    
   update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
   apt-get install -y casacore-dev casacore-tools python3-casacore cmake curl
   apt-get install -y python3-astlib python3-ipdb python3-nose python3-metaconfig jq util-linux bsdmainutils

   pip install pybind11
   pip install dask codex_africanus ephem Polygon3 pyfits pyregion terminal pyephem ptyprocess timeout-decorator astroquery
   pip install --ignore-installed numpy==1.21.6 # python -c "import numpy; print(numpy.version.version)"
   pip install reproject
   # pip install scikit-learn tqdm # scikit-learn is installed by apt / libboost 
   pip install tqdm
   export SRC=/usr/local/src

   # PyBDSF
   pip install git+https://github.com/lofar-astron/PyBDSF.git

   # LOFAR beam -- for DDF
   cd $SRC
   git clone https://github.com/lofar-astron/LOFARBeam.git
   cd LOFARBeam
   mkdir build
   cd build
   cmake ..
   make -j $J
   make install

   cd /usr/local/lib/python3.9/dist-packages/
   ln -s /usr/local/lib/python3.9/site-packages/lofar

   # dysco -- for DP3
   cd $SRC
   git clone https://github.com/aroffringa/dysco.git
   cd dysco
   # git checkout 3fd7a5fd17f3d09db89ad7827c9bdc4febf66eff
   mkdir build
   cd build
   cmake ../
   make -j $J
   make install
   cp $SRC/dysco/build/decompress /usr/local/bin/decompress  # https://github.com/aroffringa/dysco/issues/12#issuecomment-773134161

   # IDG -- for wsclean and DP3
   cd $SRC
   git clone https://gitlab.com/astron-idg/idg.git
   cd idg
   git checkout f4a3a96c # Hotfix for DP3 tec
   cd ..
   cd idg && mkdir build && cd build
   cmake -DCMAKE_INSTALL_PREFIX=/usr/local/idg/ ..
   make -j $J
   make install

   # aoflagger -- for DP3
   cd $SRC
   git clone https://gitlab.com/aroffringa/aoflagger.git
   cd aoflagger
   mkdir build
   cd build
   cmake ..
   make -j $J
   make install

   # Everybeam -- for DP3
   cd $SRC
   git clone https://git.astron.nl/RD/EveryBeam.git
   cd EveryBeam
   mkdir build
   cd build
   cmake -DBUILD_WITH_PYTHON=On ..
   make -j $J
   make install

   # SAGECal libdirac
   cd $SRC
   git clone https://github.com/nlesc-dirac/sagecal.git
   cd sagecal
   mkdir build
   cd build
   # https://en.wikichip.org/wiki/intel/xeon_gold/6238
   cmake .. -DLIB_ONLY=1 -Wno-dev -DCMAKE_CXX_FLAGS='-g -O3 -fopenmp -ffast-math -lmvec -lm -mavx2 -mavx512f' -DCMAKE_C_FLAGS='-g -O3 -fopenmp -ffast-math -lmvec -lm -mavx2 -mavx512f' # mavx512f makes the .sif file larger by ~2GB
   make -j $J
   make install

   # DP3
   cd $SRC
   git clone https://github.com/lofar-astron/DP3.git
   cd DP3
   git checkout 5dab4c43 # https://github.com/rvweeren/lofar_facet_selfcal/issues/65#issuecomment-1510280940
   cd ..
   cd DP3
   mkdir build
   cd build
   cmake .. -DLIBDIRAC_PREFIX=/usr/ -DCMAKE_PREFIX_PATH=/usr/local/idg/
   make -j $J
   make install

   # few more DDF dependencies
   pip install -U tables prettytable pylru emcee astropy_healpix sharedarray

   # losoto -- for selfcal
   pip install losoto

   # APLpy -- for selfcal
   pip install pyavm
   # pip install imageio==2.14.1
   pip install imageio
   pip install aplpy
   # pip install --ignore-installed numpy==1.21.6 # aplpy is upgrading numpy, so rolling it back

  # wsclean latest -- for selfcal
   cd $SRC
   git clone https://gitlab.com/aroffringa/wsclean.git
   cd wsclean
   mkdir -p build
   cd build
   cmake .. -DCMAKE_PREFIX_PATH=/usr/local/idg/
   make -j $J
   make install

  # DDFacet
  cd $SRC
  git clone --depth 1 -b v0.6.0 https://github.com/saopicc/DDFacet.git
  cd DDFacet
  python setup.py install

  # killMS
  cd $SRC
  git clone --depth 1 -b v3.0.1 https://github.com/saopicc/killMS.git
  cd killMS
  python setup.py install

  # dynspecMS
  cd $SRC
  git clone --depth 1 https://github.com/cyriltasse/DynSpecMS.git

  # lotss-query
  cd $SRC
  git clone --depth 1 https://github.com/mhardcastle/lotss-query.git

  # lotss-hba-survey (not needed for most users)
  cd $SRC
  git clone --depth 1 https://github.com/mhardcastle/lotss-hba-survey.git

  # ddf-pipeline
  cd $SRC
  git clone --depth 1 https://github.com/mhardcastle/ddf-pipeline.git
  # create the init script
  ddf-pipeline/scripts/install.sh
  # catalogs
  mkdir -p $SRC/catalogs/
  cd $SRC/catalogs/
  wget -q --retry-connrefused http://www.oa.uj.edu.pl/A.Kurek/bootstrap-cats.tar # https://github.com/tikk3r/flocs/blob/fedora-py3/singularity/Singularity.intel_mkl#L592
  tar xvf bootstrap-cats.tar
  rm -f bootstrap-cats.tar

  cd /usr/local/src
  wget https://rclone.org/install.sh
  bash install.sh

  cd /usr/local/src
  git clone https://github.com/sara-nl/SpiderScripts.git
  cd SpiderScripts
  cp ada/ada /usr/local/bi


  pip list

  pip cache purge
  apt-get purge -y cmake
  apt-get -y autoremove
  rm -rf /var/lib/apt/lists/*
  
  bash -c "rm -rf /usr/local/src/{DP3,EveryBeam,LOFARBeam,aoflagger,dysco,idg,wsclean,PyBDSF,SpiderScripts,sagecal}/" # DDFacet,killMS
