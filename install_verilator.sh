#!/bin/bash
#
# Install LLVM on CentOS7 platform
# Host linux is either x86_64 or aarch64
#
# How to download:
# $> curl https://raw.githubusercontent.com/snakajim/centos7_install_tools/main/install_verilator.sh
#
VERILATOR_REV="216"
URL_VERILATOR="https://github.com/verilator/verilator/tarball/v4.${VERILATOR_REV}"

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
# set CMAKE variable based on clang version.
#
which clang
ret=$?
if [ $ret == '0' ]; then
  CLANG_VERSION=$(clang --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
else
  CLANG_VERSION="0"
fi

sudo yum -y install ninja-build binutils-x86_64-linux-gnu

if [ "$CLANG_VERSION" -gt 130000 ]; then
  echo "use clang for build tool"
  export CC=`which clang`
  export CXX=`which clang++`
  export LD=`which lld`
  export CMAKE_CXX_COMPILER=`which clang++`
  export CMAKE_C_COMPILER=`which clang`
  export CMAKE_LINKER=`which lld`
else
  echo "use gcc for build tool"
  export CC=`which gcc`
  export CXX=`which g++`
  export LD=`which ld.gold`
  export CMAKE_CXX_COMPILER=`which gcc++`
  export CMAKE_C_COMPILER=`which gcc`
  export CMAKE_LINKER=`which ld.gold`
fi

#
# install verilator 4_${VERILATOR_REV}
#
unset VERILATOR_ROOT 
mkdir -p ${HOME}/tmp/verilator && rm -rf ${HOME}/tmp/verilator/*
cd ${HOME}/tmp && wget --no-check-certificate ${URL_VERILATOR} -O verilator-v4.${VERILATOR_REV}.tgz
cd ${HOME}/tmp && tar -xvf verilator-v4.${VERILATOR_REV}.tgz -C verilator --strip-components 1
start_time=`date +%s`
cd ${HOME}/tmp/verilator && autoconf && \
  ./configure --prefix=/usr/local/verilator_4_${VERILATOR_REV} \
  CC=$CC \
  CXX=$CXX && \
  make -j`nproc` &> ${HOME}/run_verilator${VERILATOR_REV}.log && \
  sudo make install
end_time=`date +%s`
run_time=$((end_time - start_time))
sudo ln -sf /usr/local/verilator_4_${VERILATOR_REV}/bin/verilator* /usr/local/verilator_4_${VERILATOR_REV}/share/verilator/bin/
#cd ${HOME}/tmp/verilator && make clean

#
# report log
#
echo "cat /proc/cpuinfo" >> ${HOME}/run_verilator${VERILATOR_REV}.log
cat /proc/cpuinfo  >> ${HOME}/run_verilator${VERILATOR_REV}.log
echo "nproc" >> ${HOME}/run_verilator${VERILATOR_REV}.log
nproc >> ${HOME}/run_verilator${VERILATOR_REV}.log
echo "tool chain version" >> ${HOME}/run_verilator${VERILATOR_REV}.log
$CC --version >> ${HOME}/run_verilator${VERILATOR_REV}.log
echo "install_verilator.sh costs $run_time [sec]." >> ${HOME}/run_verilator${VERILATOR_REV}.log
echo ""

#
# .bashrc set
#
cd ${HOME} && \
  echo "# " >> .bashrc
cd ${HOME} && \
  echo "# verilator setting" >> .bashrc
cd ${HOME} && \
  echo "export VERILATOR_ROOT=/usr/local/verilator_4_${VERILATOR_REV}/share/verilator">> .bashrc
cd ${HOME} && \
  echo "export PATH=\$VERILATOR_ROOT/bin:\$PATH" >> .bashrc

cd /etc/skel && \
  sudo echo "# " >> .bashrc
cd /etc/skel && \
  sudo echo "# verilator setting" >> .bashrc
cd /etc/skel && \
  sudo echo "export VERILATOR_ROOT=/usr/local/verilator_4_${VERILATOR_REV}/share/verilator">> .bashrc
cd /etc/skel && \
  sudo echo "export PATH=\$VERILATOR_ROOT/bin:\$PATH" >> .bashrc
