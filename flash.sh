#!/bin/bash

if [ -f ./flash.sh ]; then
	. ./flash.sh
	exit 0
fi

source ~/env/set_env.sh
RAMDISK=$RAMDISK_TW
cleardir $RAMDISK
BOARD="SYSMAGIC000KU"
DTS="exynos5433-trelte_kor_open_12.dtb"
DTB="n910-dt.img"
COMPRESS="gzip -9"
rm $TMPDIR/* 2>/dev/null

if [ ! -e ./arch/arm/boot/zImage ]; then
	mmc && flat && ss300 && clean
    mtp_sec && make -j4
fi

echo "* buid dtb *"
rm ~/env/arch/arm/boot/dts/*.dtb 2>/dev/null
make $DTS
~/env/utility/dtbtool -o ~/env/utility/$DTB -s 2048 -p ./scripts/dtc/ ./arch/arm/boot/dts/

echo ""
echo RAMDISK: $RAMDISK

~/env/utility/mkbootfs $RAMDISK | $COMPRESS > $TMPDIR/ramdisk.img
~/env/utility/mkbootimg --base 0x10000000 --pagesize 2048 --board $BOARD --kernel ./arch/arm/boot/zImage --ramdisk $TMPDIR/ramdisk.img --dt ~/env/utility/$DTB -o $TMPDIR/boot.img
echo -n "SEANDROIDENFORCE" >> $TMPDIR/boot.img
cp -f  $TMPDIR/boot.img ~/HostPC/Kernel/boot.img

echo ""
echo - wating device...
#adb wait-for-device
echo - push boot.img to /device/sdcard/ ...
adb shell "rm -f /data/local/tmp/boot.img"
adb shell "rm -f /data/stock_boot.img 2>/dev/null||su -c 'rm /data/stock_boot.img'"
adb push $TMPDIR/boot.img /data/local/tmp/boot.img
echo - flashing image...
adb shell 'dd if=/data/local/tmp/boot.img of=/dev/block/mmcblk0p9 2>/dev/null||su -c "dd if=/data/local/tmp/boot.img of=/dev/block/mmcblk0p9"'
adb shell "rm -f /data/local/tmp/boot.img"
echo - flashing done. device reboot after 2s
rm $TMPDIR/* 2>/dev/null
sleep 2
adb reboot recovery
echo ""

