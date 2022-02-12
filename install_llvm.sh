#!/bin/bash
#
# Install LLVM on CentOS7 platform
# Host linux is either x86_64 or aarch64
#
FORCE_PREBUILD=1
LLVM_VERSION="13.0.0"
LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz"
LLVM_PREBUILD_AARCH64="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz"
LLVM_PREBUILD_X86_64="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-20.04.tar.xz"

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
# Check CMAKE version > 3.22.1
#
CMAKE_VERSION=$(cmake --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
if [ "$CMAKE_VERSION" -lt 31200 ]; then
  echo "CMAKE is too old to build llvm ${LLVM_VERSION}. Program exit."
  exit
fi

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

if ( ( [ $HOSTARCH == "aarch64" ]  && [ $FORCE_PREBUILD == "0" ] ) || ( [ $HOSTARCH == "x86_64" ] && [ $FORCE_PREBUILD == "0" ] ) ) && [ "$CLANG_VERSION" -lt 120000 ]; then
  echo "Your clang is not new. Need to update."
  echo `clang --version`
  if [ ! -f ${HOME}/tmp/llvm-project-${LLVM_VERSION}.src.tar.xz ]; then
    mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && aria2c -x10 $LLVM_URL
  fi
  cd ${HOME}/tmp && unxz -k -T `nproc` -f llvm-project-${LLVM_VERSION}.src.tar.xz && \
    tar xf llvm-project-${LLVM_VERSION}.src.tar && \
    cd llvm-project-${LLVM_VERSION}.src && mkdir -p build && cd build
  start_time=`date +%s`
  cmake -G Ninja -G "Unix Makefiles"\
    -DCMAKE_C_COMPILER=`which gcc` \
    -DCMAKE_CXX_COMPILER=`which g++` \
    -DLLVM_ENABLE_PROJECTS="clang;llvm;lld" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM"\
    -DCMAKE_INSTALL_PREFIX="/usr/local/llvm_${LLVM_VERSION}" \
    ../llvm && make -j`nproc`
  end_time=`date +%s`
  run_time=$((end_time - start_time))
  sudo make install && make clean && cd ../ && rm -rf build && cd ${HOME}
fi

if ( [ $HOSTARCH == "x86_64" ]  && [ $FORCE_PREBUILD == "1" ] ) && [ "$CLANG_VERSION" -lt 120000 ]; then
  echo "Your clang is not new. Need to update from prebuild."
  echo `clang --version`
  if [ ! -f ${HOME}/tmp/clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-20.04.tar.xz ]; then
    mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && aria2c -x10 $LLVM_PREBUILD_X86_64
  fi
  cd ${HOME}/tmp && unxz -k -T `nproc` -f clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-20.04.tar.xz
  sudo mkdir -p /usr/local/llvm_${LLVM_VERSION}
  cd ${HOME}/tmp && sudo tar xf clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-20.04.tar --strip-components 1 -C /usr/local/llvm_${LLVM_VERSION}
fi


if ( [ $HOSTARCH == "aarch64" ]  && [ $FORCE_PREBUILD == "1" ] ) && [ "$CLANG_VERSION" -lt 120000 ]; then
  echo "Your clang is not new. Need to update from prebuild."
  echo `clang --version`
  if [ ! -f ${HOME}/tmp/clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz ]; then
    mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && aria2c -x10 $LLVM_PREBUILD_AARCH64
  fi
  cd ${HOME}/tmp && unxz -k -T `nproc` -f clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz
  sudo mkdir -p /usr/local/llvm_${LLVM_VERSION}
  cd ${HOME}/tmp && sudo tar xf clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar --strip-components 1 -C /usr/local/llvm_${LLVM_VERSION}
fi

#
# Update ~/.bashrc if necesarry
#
grep LLVM_VERSION ${HOME}/.bashrc
ret=$?
if [ $ret == "1" ] && [ -d /usr/local/llvm_${LLVM_VERSION} ]; then
    echo "# " >> ${HOME}/.bashrc
    echo "# LLVM setting to \${LLVM_VERSION}"   >> ${HOME}/.bashrc
    echo "# " >> ${HOME}/.bashrc
    echo "export LLVM_VERSION=${LLVM_VERSION}" >> ${HOME}/.bashrc
    echo "export LLVM_DIR=/usr/local/llvm_\${LLVM_VERSION}">> ${HOME}/.bashrc
    echo "export PATH=\$LLVM_DIR/bin:\$PATH"   >>  ${HOME}/.bashrc
    echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH"   >>  ${HOME}/.bashrc
    echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH"   >>  ${HOME}/.bashrc
    echo "export LLVM_CONFIG=\$LLVM_DIR/bin/llvm-config"   >>  ${HOME}/.bashrc
    # root /etc/skel
    sudo echo "# " >> /etc/skel/.bashrc
    sudo echo "# LLVM setting to \${LLVM_VERSION}"   >> /etc/skel/.bashrc
    sudo echo "# " >> /etc/skel/.bashrc
    sudo echo "export LLVM_VERSION=${LLVM_VERSION}" >> /etc/skel/.bashrc
    sudo echo "export LLVM_DIR=/usr/local/llvm_\${LLVM_VERSION}">> /etc/skel/.bashrc
    sudo echo "export PATH=\$LLVM_DIR/bin:\$PATH"   >>  /etc/skel/.bashrc
    sudo echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH"   >>  /etc/skel/.bashrc
    sudo echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH"   >>  /etc/skel/.bashrc
    sudo echo "export LLVM_CONFIG=\$LLVM_DIR/bin/llvm-config"   >>  /etc/skel/.bashrc
fi

echo "cat /proc/cpuinfo" > ${HOME}/tmp/run.log
cat /proc/cpuinfo  >> ${HOME}/tmp/run.log
echo "nproc" >> ${HOME}/tmp/run.log
nproc >> ${HOME}/tmp/run.log
echo "/usr/bin/g++ version" >> ${HOME}/tmp/run.log
/usr/bin/g++ --version >> ${HOME}/tmp/run.log
echo "install_llvm.sh costs $run_time [sec]." >> ${HOME}/tmp/run.log
echo ""
