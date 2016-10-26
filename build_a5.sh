#
# Copyright � 2016,  Sultan Qasim Khan <sultanqasim@gmail.com>
# Copyright � 2016,  Zeeshan Hussain <zeeshanhussain12@gmail.com>
# Copyright � 2016,  Varun Chitre  <varun.chitre15@gmail.com>
# Copyright � 2016,  Aman Kumar  <firelord.xda@gmail.com>
# Copyright � 2016,  Kartik Bhalla <kartikbhalla12@gmail.com> 

# Custom build script
#
# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Please maintain this if you use this script or any part of it
#

#!/bin/bash
KERNEL_DIR=~/android_dev/xos77/kernel/htc/msm8974
KERN_IMG=$KERNEL_DIR/arch/arm/boot/zImage
DTBTOOL=$KERNEL_DIR/tools/dtbToolCM
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
export ARCH=arm
export SUBARCH=arm
export PATH=${PATH}:/home/jbw716/android_dev/xos77/prebuilts/gcc/linux-x86/arm/arm-eabi-5.3/bin
export CROSS_COMPILE=/home/jbw716/android_dev/xos77/prebuilts/gcc/linux-x86/arm/arm-eabi-5.3/bin/arm-eabi-
export KBUILD_BUILD_USER="hunterbruhh"
export KBUILD_BUILD_HOST="hunterbruhh"
rm -f arch/arm/boot/dts/*.dtb
rm -f arch/arm/boot/dt.img
rm -f flash_zip/boot.img

compile_kernel ()
{
  echo -e "$cyan***********************************************"
  echo -e "          Initializing defconfig          "
  echo -e "***********************************************$nocol"
  make cm_a5_defconfig
  echo -e "$cyan***********************************************"
  echo -e "             Building kernel          "
  echo -e "***********************************************$nocol"
  make -j8 zImage
  if ! [ -a $KERN_IMG ];
  then
    echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
    exit 1
  fi
  echo -e "$cyan***********************************************"
  echo -e "          	  Making DTB          "
  echo -e "***********************************************$nocol"
  make -j8 dtbs
  $DTBTOOL -s 2048 -d "htc,project-id = <" -o $KERNEL_DIR/arch/arm/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
  echo -e "$cyan***********************************************"
  echo -e "         	Building modules          "
  echo -e "***********************************************$nocol"
  make -j8 modules
}

zip_kernel ()
{
  echo -e "$cyan***********************************************"
  echo "          Compiling hunterbruhh kernel          "
  echo -e "***********************************************$nocol"
  echo -e " "
  echo -e " SELECT ONE OF THE FOLLOWING TYPES TO BUILD : "
  echo -e " 1.DIRTY"
  echo -e " 2.CLEAN"
  echo -n " YOUR CHOICE : ? "
  read ch
  echo -n " Which device : ? "
  read dev
  echo -n " Which android mm or n : ? "
  read anv

case $ch in
  1) echo -e "$cyan***********************************************"
     echo -e "          	Dirty          "
     echo -e "***********************************************$nocol"
     compile_kernel ;;
  2) echo -e "$cyan***********************************************"
     echo -e "          	Clean          "
     echo -e "***********************************************$nocol"
     make clean
     make mrproper
     compile_kernel ;;
  *) device ;;
esac
echo -e "$cyan***********************************************"
echo -e " Converting the output into a flashable zip"
echo -e "***********************************************$nocol"
rm -rf kernel_install
mkdir -p kernel_install
make -j4 modules_install INSTALL_MOD_PATH=kernel_install INSTALL_MOD_STRIP=1
mkdir -p flash_zip/system/lib/modules/
find kernel_install/ -name '*.ko' -type f -exec cp '{}' flash_zip/system/lib/modules/ \;
cp arch/arm/boot/zImage flash_zip/tools/
cp dt.img flash_zip/tools/
rm -rf ~/android_dev/xos77/flashme
mkdir -p ~/android_dev/xos77/flashme
cd flash_zip
zip -r ../arch/arm/boot/final_kernel.zip ./
today=$(date +"-%d%m%Y")
mv $KERNEL_DIR/arch/arm/boot/final_kernel.zip ~/android_dev/xos77/flashme/a5Kernel-$anv-$dev-$today.zip
}
zip_kernel
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
