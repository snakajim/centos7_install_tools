#  ---------------------------------------------------------------------------------
# SCL to install gcc7/8, and set GCC8 as default compiler
#  ---------------------------------------------------------------------------------
# How to download
# $>curl https://raw.githubusercontent.com/snakajim/centos7_install_tools/main/change_gcc_ver.sh
#
yum -y install centos-release-scl
yum -y install devtoolset-7-gcc devtoolset-7-gcc-c++
yum -y install devtoolset-8-gcc devtoolset-8-gcc-c++
scl enable devtoolset-8 bash
#
# switching default gcc and g++ to version-8.
#
cd /root && \
  echo "# " >> .bashrc
cd /root && \
  echo "# gcc 8.3.1 setting for cmake" >> .bashrc
cd /root && \
  echo "export CMAKE_CXX_COMPILER=/opt/rh/devtoolset-8/root/usr/bin/gcc++">> .bashrc
cd /root && \
  echo "export CMAKE_C_COMPILER=/opt/rh/devtoolset-8/root/usr/bin/gcc">> .bashrc

cd /root && \
  echo "# " >> .bashrc
cd /root && \
  echo "# make sure your CC and CXX to new version" >> .bashrc
cd /root && \
  echo "export CXX=/opt/rh/devtoolset-8/root/usr/bin/g++">> .bashrc
cd /root && \
  echo "export CC=/opt/rh/devtoolset-8/root/usr/bin/gcc">> .bashrc

cd /etc/skel && \
  echo "# " >> .bashrc
cd /etc/skel && \
  echo "# gcc 8.3.1 setting for cmake" >> .bashrc
cd /etc/skel && \
  echo "export CMAKE_CXX_COMPILER=/opt/rh/devtoolset-8/root/usr/bin/gcc++" >> .bashrc
cd /etc/skel && \
  echo "export CMAKE_C_COMPILER=/opt/rh/devtoolset-8/root/usr/bin/gcc" >> .bashrc

cd /etc/skel && \
  echo "# " >> .bashrc
cd /etc/skel && \
  echo "# make sure your CC and CXX to new version" >> .bashrc
cd /etc/skel && \
  echo "export CXX=/opt/rh/devtoolset-8/root/usr/bin/g++" >> .bashrc
cd /etc/skel && \
  echo "export CC=/opt/rh/devtoolset-8/root/usr/bin/gcc" >> .bashrc

