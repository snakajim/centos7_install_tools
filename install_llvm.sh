#!/bin/bash
#
# Install LLVM on CentOS7 platform
# Host linux is either x86_64 or aarch64
#
# How to download:
# $> curl https://raw.githubusercontent.com/snakajim/centos7_install_tools/main/install_llvm.sh
#
FORCE_PREBUILD=0
LLVM_VERSION="15.0.1"
#LLVM_PREFIX="/usr/local/llvm_${LLVM_VERSION}"
LLVM_PREFIX="/usr"
LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz"

# OS Version check
CENTOS_VERSION=$(cat /etc/os-release | grep "PRETTY_NAME=" | sed -r 's#^PRETTY_NAME="CentOS\s+Linux\s+([0-9]).+#\1#')
if [ $CENTOS_VERSION != "7" ]; then
  echo "CENTOS_VERSION mismatch or using another Linux distribution, $CENTOS_VERSION. Program exit."
  exit
fi

# Gcc version check
GCC_VERSION=$(gcc --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
if [ $GCC_VERSION -lt 70000 ]; then
  echo "Your gcc is too old to build llvm. Program exit."
  exit
fi

# Check CMAKE version > 3.22.1
CMAKE_VERSION=$(cmake --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
if [ "$CMAKE_VERSION" -lt 31200 ]; then
  echo "CMAKE is too old to build llvm ${LLVM_VERSION}. Program exit."
  exit
fi

#
# Function hostarch()
# set $HOSTARCH 
#
function hostarch () {
  HOSTARCH=`uname -m`
  if [ $HOSTARCH == "x86_64" ]; then
    HOSTARCH="x86_64"
  else
    if [ $HOSTARCH == "aarch64" ]; then
      HOSTARCH="aarch64"
    else
      HOSTARCH="unknown"
      echo "My HOSTARCH=$HOSTARCH, Program exit"
      exit
    fi
  fi
  echo "My HOSTARCH=$HOSTARCH"
}

# identify host architecture
hostarch

#
# install LLVM ${LLVM_VERSION} if not available
#
which clang
ret=$?
if [ $ret == '0' ]; then
  CLANG_VERSION=$(clang --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
else
  CLANG_VERSION="0"
fi

sudo yum -y install ninja-build libedit-devel libxml2-devel ncurses-devel python-devel swig

if ( ( [ $HOSTARCH == "aarch64" ]  && [ $FORCE_PREBUILD == "0" ] ) || ( [ $HOSTARCH == "x86_64" ] && [ $FORCE_PREBUILD == "0" ] ) ) && [ "$CLANG_VERSION" -lt 120000 ]; then
  echo "Your clang is not new. Need to update."
  echo `clang --version`
  sudo yum -y remove clang
  if [ ! -f ${HOME}/tmp/llvm-project-${LLVM_VERSION}.src.tar.xz ]; then
    mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && aria2c -x10 $LLVM_URL
  fi
  cd ${HOME}/tmp && unxz -k -T `nproc` -f llvm-project-${LLVM_VERSION}.src.tar.xz && \
    tar xf llvm-project-${LLVM_VERSION}.src.tar && \
    cd llvm-project-${LLVM_VERSION}.src && mkdir -p build && cd build
  start_time=`date +%s`
  cmake -G "Ninja" -G "Unix Makefiles"\
    -DCMAKE_C_COMPILER=`which gcc` \
    -DCMAKE_CXX_COMPILER=`which g++` \
    -DLLVM_ENABLE_PROJECTS="clang;llvm;lld;lldb" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM"\
    -DCMAKE_INSTALL_PREFIX=${LLVM_PREFIX} \
    ../llvm && cmake --build . -j`nproc`
  sudo make install
  end_time=`date +%s`
  run_time=$((end_time - start_time))
  make clean && cd ${HOME}
fi

if ( [ $HOSTARCH == "x86_64" ]  && [ $FORCE_PREBUILD == "1" ] ) && [ "$CLANG_VERSION" -lt 120000 ]; then
  echo "LLVM PREBUILD for CENTOS7 is not available. Program exit."
  exit
fi

if ( [ $HOSTARCH == "aarch64" ]  && [ $FORCE_PREBUILD == "1" ] ) && [ "$CLANG_VERSION" -lt 120000 ]; then
  echo "LLVM PREBUILD for CENTOS7 is not available. Program exit."
  exit
fi

#
# Report log
#
echo "cat /proc/cpuinfo" > ${HOME}/run_llvm${LLVM_VERSION}.log
cat /proc/cpuinfo  >> ${HOME}/run_llvm${LLVM_VERSION}.log
echo "nproc" >> ${HOME}/run_llvm${LLVM_VERSION}.log
nproc >> ${HOME}/run_llvm${LLVM_VERSION}.log
echo "/usr/bin/g++ version" >> ${HOME}/run_llvm${LLVM_VERSION}.log
/usr/bin/g++ --version >> ${HOME}/run_llvm${LLVM_VERSION}.log
echo "install_llvm.sh costs $run_time [sec]." >> ${HOME}/run_llvm${LLVM_VERSION}.log
echo ""

#
# Update ~/.bashrc if necesarry
#
grep LLVM_VERSION ${HOME}/.bashrc
ret=$?
if [ $ret == "1" ] && [ -d ${LLVM_PREFIX} ] && [ ${LLVM_PREFIX} != "/usr" ]; then
    echo "# " >> ${HOME}/.bashrc
    echo "# LLVM setting to \${LLVM_VERSION}"   >> ${HOME}/.bashrc
    echo "# " >> ${HOME}/.bashrc
    echo "export LLVM_VERSION=${LLVM_VERSION}" >> ${HOME}/.bashrc
    echo "export LLVM_DIR=${LLVM_PREFIX}">> ${HOME}/.bashrc
    echo "export PATH=\$LLVM_DIR/bin:\$PATH"   >>  ${HOME}/.bashrc
    echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH"   >>  ${HOME}/.bashrc
    echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH"   >>  ${HOME}/.bashrc
    echo "export LLVM_CONFIG=\$LLVM_DIR/bin/llvm-config"   >>  ${HOME}/.bashrc
    source ~/.bashrc
    # root /etc/skel
    sudo echo "# " >> /etc/skel/.bashrc
    sudo echo "# LLVM setting to \${LLVM_VERSION}"   >> /etc/skel/.bashrc
    sudo echo "# " >> /etc/skel/.bashrc
    sudo echo "export LLVM_VERSION=${LLVM_VERSION}" >> /etc/skel/.bashrc
    sudo echo "export LLVM_DIR=${LLVM_PREFIX}">> /etc/skel/.bashrc
    sudo echo "export PATH=\$LLVM_DIR/bin:\$PATH"   >>  /etc/skel/.bashrc
    sudo echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH"   >>  /etc/skel/.bashrc
    sudo echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH"   >>  /etc/skel/.bashrc
    sudo echo "export LLVM_CONFIG=\$LLVM_DIR/bin/llvm-config"   >>  /etc/skel/.bashrc
fi

sudo ldconfig
