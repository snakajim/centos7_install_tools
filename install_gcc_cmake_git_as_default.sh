#!/bin/bash
# install_gcc_cmake_git_as_default.sh
# SYNOPSIS
# Install essential tools to newer version from source, and set as default 
#   gcc: gcc7.5.0-2019-11-14 http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-7.5.0/gcc-7.5.0.tar.gz
#   git: 2.33.1-2021-10-13 https://github.com/git/git.git -b v2.33.1
# cmake: 3.18.6-2021-02-11 https://cmake.org/files/v3.18/cmake-3.18.6.tar.gz
#
GCC_VERSION=
GIT_VERSION=
CMAKE_VERSION=
CENTOS_VERSION=`cat /etc/os-release | grep "PRETTY_NAME=" | sed 's#PRETTY_NAME="(\.+)"#$1#'`

