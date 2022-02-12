#!/bin/bash
# install_gcc_cmake_git_as_default.sh
# SYNOPSIS
# Install essential tools to newer version from source, and set as default 
#   gcc: gcc7.5.0-2019-11-14 http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-7.5.0/gcc-7.5.0.tar.gz
#   git: 2.33.1-2021-10-13 https://github.com/git/git.git -b v2.33.1
# cmake: 3.18.6-2021-02-11 https://cmake.org/files/v3.18/cmake-3.18.6.tar.gz
#
# How to download:
# $> curl https://raw.githubusercontent.com/snakajim/centos7_install_tools/main/install_gcc_cmake_git_as_default.sh > install_gcc_cmake_git_as_default.sh
#
GCC_VERSION=$(gcc --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
CMAKE_VERSION=$(cmake --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
GIT_VERSION=$(git --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
CENTOS_VERSION=$(cat /etc/os-release | grep "PRETTY_NAME=" | sed -r 's#^PRETTY_NAME="CentOS\s+Linux\s+([0-9]).+#\1#')

# install dependencies for build tools
sudo yum -y install wget aria2 git

# OS Version check
if [ $CENTOS_VERSION != "7" ]; then
  echo "CENTOS_VERSION mismatch or using another Linux distribution, $CENTOS_VERSION. Program exit."
  exit
fi

# Tool version check and install if needed
if [ $GCC_VERSION -gt 70300 ]; then
  echo "Your gcc is new, no need to refresh. Installation skip."
else
  echo "Your gcc is old, replace under /usr/bin."
  mkdir -p ${HOME}/tmp/gcc && rm -rf ${HOME}/tmp/gcc/* && cd ${HOME}/tmp/gcc && \
    aria2c -x4 http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-7.5.0/gcc-7.5.0.tar.gz
  cd ${HOME}/tmp/gcc && tar -zxvf gcc-7.5.0.tar.gz && cd gcc-7.5.0 && ./contrib/download_prerequisites
  cd ${HOME}/tmp/gcc/gcc-7.5.0 && mkdir -p build && cd build && ../configure --enable-languages=c,c++ --prefix=/usr --disable-multilib
  cd ${HOME}/tmp/gcc/gcc-7.5.0/build && make -j`nproc`
  cd ${HOME}/tmp/gcc/gcc-7.5.0/build && sudo make install
  sudo mv /usr/lib64/libstdc++.so.6.0.24-gdb.py /usr/lib64/back_libstdc++.so.6.0.24-gdb.py
  sudo sed -i -e '$ a /usr/lib64' /etc/ld.so.conf
  sudo ldconfig -v
  cd ${HOME}/tmp && rm -rf ${HOME}/tmp/gcc
fi

if [ $GIT_VERSION -gt 23000 ]; then
  echo "Your gcc is new, no need to refresh. Installation skip."
else
  echo "Your git is old, replace under /usr/bin."
  sudo yum -y remove git
  mkdir -p ${HOME}/tmp/git && rm -rf ${HOME}/tmp/git/* && cd ${HOME}/tmp/git && \
    aria2c -x4 https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.33.1.tar.gz
  cd ${HOME}/tmp/git && tar -zxvf git-2.33.1.tar.gz
  cd ${HOME}/tmp/git/git-2.33.1 && mkdir -p build && cd build && ../configure --prefix=/usr && make -j`nproc`
  cd ${HOME}/tmp/git/git-2.33.1/build && sudo make install
  sudo ldconfig -v
  cd ${HOME}/tmp && rm -rf ${HOME}/tmp/git
fi

if [ $CMAKE_VERSION -gt 31500 ]; then
  echo "Your gcc is new, no need to refresh. Installation skip."
else
  echo "Your cmake is old, replace under /usr/bin."
  sudo yum -y remove cmake
  mkdir -p ${HOME}/tmp/cmake && rm -rf ${HOME}/tmp/cmake/* && cd ${HOME}/tmp/cmake && \
  aria2c -x4 https://cmake.org/files/v3.18/cmake-3.18.6.tar.gz
  cd ${HOME}/tmp/cmake && tar -zxvf cmake-3.18.6.tar.gz
  cd ${HOME}/tmp/cmake/cmake-3.18.6 && mkdir -p build && cd build && ../configure --prefix=/usr && make -j`nproc`
  cd ${HOME}/tmp/cmake/cmake-3.18.6/build && sudo make install
  sudo ldconfig -v
  cd ${HOME}/tmp && rm -rf ${HOME}/tmp/cmake
fi

