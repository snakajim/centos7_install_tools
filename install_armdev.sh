#!/bin/bash
# Install arm dev tools
#
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

GCC_VER="11.3.rel1"
GCC_DIR="/usr/local/${GCC_VER}"

if ( [ $HOSTARCH == "aarch64" ] ) || ( [ $HOSTARCH == "x86_64" ] ) ; then
  mkdir -p ~/tmp/${HOSTARCH} && cd ~/tmp/${HOSTARCH} 
  # AArch32 bare-metal target (arm-none-eabi)
  aria2c -x10 https://developer.arm.com/-/media/Files/downloads/gnu/${GCC_VER}/binrel/arm-gnu-toolchain-${GCC_VER}-${HOSTARCH}-arm-none-eabi.tar.xz
  # AArch32 GNU/Linux target with hard float (arm-none-linux-gnueabihf)
  aria2c -x10 https://developer.arm.com/-/media/Files/downloads/gnu/${GCC_VER}/binrel/arm-gnu-toolchain-${GCC_VER}-${HOSTARCH}-arm-none-linux-gnueabihf.tar.xz
  # AArch64 ELF bare-metal target (aarch64-none-elf)
  aria2c -x10 https://developer.arm.com/-/media/Files/downloads/gnu/${GCC_VER}/binrel/arm-gnu-toolchain-${GCC_VER}-${HOSTARCH}-aarch64-none-elf.tar.xz
  # 
else
  echo "Invalid architecture found. Program exit."
  exit
fi

#
# Install and set path
#
sudo mkdir -p ${GCC_DIR}
sudo tar -Jxvf ~/tmp/${HOSTARCH}/arm-gnu-toolchain-${GCC_VER}-${HOSTARCH}-arm-none-eabi.tar.xz -C ${GCC_DIR}
sudo tar -Jxvf ~/tmp/${HOSTARCH}/arm-gnu-toolchain-${GCC_VER}-${HOSTARCH}-arm-none-linux-gnueabihf.tar.xz -C ${GCC_DIR}
sudo tar -Jxvf ~/tmp/${HOSTARCH}/arm-gnu-toolchain-${GCC_VER}-${HOSTARCH}-aarch64-none-elf.tar.xz -C ${GCC_DIR}
echo "# AArch32 bare-metal target (arm-none-eabi)" >> ${HOME}/.bashrc
echo "export PATH=${GCC_DIR}/arm-gnu-toolchain-${GCC_VER}-${HOSTARCH}-arm-none-eabi/bin:\$PATH" >> ${HOME}/.bashrc
echo "# AArch32 GNU/Linux target with hard float (arm-none-linux-gnueabihf)" >> ${HOME}/.bashrc
echo "export PATH=${GCC_DIR}/arm-gnu-toolchain-${GCC_VER}-${HOSTARCH}-arm-none-linux-gnueabihf/bin:\$PATH" >> ${HOME}/.bashrc
echo "# AArch64 bare-metal target (aarch64-none-elf)" >> ${HOME}/.bashrc
echo "export PATH=${GCC_DIR}/arm-gnu-toolchain-${GCC_VER}-${HOSTARCH}-aarch64-none-elf/bin:\$PATH" >> ${HOME}/.bashrc
  