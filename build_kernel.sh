#!/bin/bash

source ~/env/set_env.sh
rm $TMPDIR/* 2> /dev/null
rm .version 2>/dev/null

cleardir > /dev/null 2>&1

function wait_device() {
	echo "- adb: wating for device..."

	if [ -z $1 ]; then
		while [ "$(adb get-state)" == "unknown" ]; do
			busybox usleep 500000
		done
	else
		while [ "$(adb shell "uname")" == "Linux" ]; do
			busybox usleep 500000
		done
		while [ "$(adb get-state)" != "$1" ]; do
			busybox usleep 500000
		done
	fi
}

for VARIANT in $BUILD_VARIANTS
do
	echo ""
	echo "------------------------ build $VARIANT zImage ----------------------------"
	echo ""
    case $VARIANT in
      n916-tw)
        BOARD="SYSMAGIC001KU"
    	DTS=""
		DTB="n916s-boot.img-dtb"
    	RAMDISK=$RAMDISK_TW
        RAMDISK_NAME="ramdisk-tw.img"
        COMPRESS="gzip -9"
        IMG_NAME="${VARIANT}-boot.img"
        ADD_MODULES=0
        mtp_sec && ufs1 && flat && ss333
      ;;
      n915-tw)
        BOARD="SYSMAGIC000KU"
		DTS="exynos5433-tbelte_kor_open_14.dtb"
		DTB="n915-dt.img"
    	RAMDISK=$RAMDISK_TW
        RAMDISK_NAME="ramdisk-tw.img"
        COMPRESS="gzip -9"
        IMG_NAME="${VARIANT}-boot.img"
        ADD_MODULES=0
    	mtp_sec && mmc && edge && ss300
      ;;
      n910kor-tw)
        BOARD="SYSMAGIC000KU"
		DTS="exynos5433-trelte_kor_open_12.dtb"
		DTB="n910k-dt.img"
    	RAMDISK=$RAMDISK_TW
        RAMDISK_NAME="ramdisk-tw.img"
        COMPRESS="gzip -9"
        IMG_NAME="${VARIANT}-boot.img"
        ADD_MODULES=0
    	mtp_sec && mmc && flat && ss300
      ;;
      n910ch-tw)
        BOARD="SYSMAGIC000KU"
		DTS=""
		DTB="n910c-boot.img-dtb"
    	RAMDISK=$RAMDISK_TW
        RAMDISK_NAME="ramdisk-tw.img"
        COMPRESS="gzip -9"
        IMG_NAME="${VARIANT}-boot.img"
        ADD_MODULES=0
    	mtp_sec && mmc && flat && m7400
      ;;
      n910u-tw)
        BOARD="SYSMAGIC000KU"
		DTS=""
		DTB="n910u-boot.img-dtb"
    	RAMDISK=$RAMDISK_TW
        RAMDISK_NAME="ramdisk-tw.img"
        COMPRESS="gzip -9"
        IMG_NAME="${VARIANT}-boot.img"
        ADD_MODULES=0
    	mtp_sec && mmc && flat && m72xx
      ;;

      n916-twrp)
        BOARD="SYSMAGIC001KU"
    	DTS=""
    	DTB="n916s-boot.img-dtb"
    	RAMDISK=$RAMDISK_TWRP
        RAMDISK_NAME="ramdisk-twrp.img"
        COMPRESS="lzma -9"
        IMG_NAME="n916-recovery.img"
        ADD_MODULES=0
        mtp_nosec && ufs1 && flat && ss333
      ;;
      n915-twrp)
        BOARD="SYSMAGIC000KU"
		DTS="exynos5433-tbelte_kor_open_14.dtb"
		DTB="n915-dt.img"
    	RAMDISK=$RAMDISK_TWRP
        RAMDISK_NAME="ramdisk-twrp.img"
        COMPRESS="lzma -9"
        IMG_NAME="n915-recovery.img"
        ADD_MODULES=0
    	mtp_nosec && mmc && edge && ss300
      ;;
      n910-twrp)
        BOARD="SYSMAGIC000KU"
		DTS="exynos5433-trelte_kor_open_12.dtb"
		DTB="n910-dt.img"
    	RAMDISK=$RAMDISK_TWRP
        RAMDISK_NAME="ramdisk-twrp.img"
        COMPRESS="lzma -9"
        IMG_NAME="n910-recovery.img"
        ADD_MODULES=0
    	mtp_nosec && mmc && flat && ss300
      ;;
    esac
    
	if [ $VARIANT == "n910ch-tw" ] || [ $VARIANT == "n910u-tw" ]; then
		n910c && make -j4 && n910k
	else
		make -j4
	fi

	if [ "$DTS" != "" ]; then
		echo ""
		echo ""
		echo "********* buid dtb ********"
		echo ""
		rm ~/env/arch/arm/boot/dts/*.dtb 2>/dev/null
		make $DTS
		~/env/utility/dtbtool -o ~/env/utility/$DTB -s 2048 -p ./scripts/dtc/ ./arch/arm/boot/dts/
	fi
	if [ $ADD_MODULES -eq 1 ]; then
		for i in $(find ./ -name '*.ko'); do
			cp -av "$i" $RAMDISK/lib/modules/ >/dev/null 2>&1
			rm -f "$i" >/dev/null 2>&1
			echo $i
		done;
	fi
	~/env/utility/mkbootfs $RAMDISK | $COMPRESS > ~/env/utility/$RAMDISK_NAME
	cp -f ./arch/arm/boot/zImage ~/env/utility/${VARIANT}-zImage
	~/env/utility/mkbootimg --base 0x10000000 --pagesize 2048 --board $BOARD --kernel ~/env/utility/${VARIANT}-zImage --ramdisk ~/env/utility/$RAMDISK_NAME --dt ~/env/utility/$DTB -o $TMPDIR/$IMG_NAME
	echo -n "SEANDROIDENFORCE" >> $TMPDIR/$IMG_NAME
	cp -f $TMPDIR/$IMG_NAME ~/HostPC/Kernel/$IMG_NAME

    cd $CDIR
done

mpt_sec && mmc && ss300 & flat

cd $TMPDIR

echo ""
echo ""
echo "== build image list =="
ls
echo ""

bootimg=$(ls *boot.img 2>/dev/null)
recoveryimg=$(ls *recovery.img 2>/dev/null)
if [ "$bootimg" ]; then
    tar -cf bootimg.tar *-boot.img
    xz -z -9 bootimg.tar
	mv -f bootimg.tar.xz ~/env/build-files/kernel-zip/bootimg.tar.xz
	cd ~/env/build-files/kernel-zip
	rm $KERNEL_NAME > /dev/null 2>&1
	rm ~/HostPC/Kernel/out/$KERNEL_NAME > /dev/null 2>&1
	echo $KERNEL_VERSION > version
	7z a -mx9 $KERNEL_NAME *
	zipalign -v 4 $KERNEL_NAME ~/HostPC/Kernel/out/$KERNEL_NAME
	rm bootimg.tar.xz > /dev/null 2>&1
	rm $KERNEL_NAME > /dev/null 2>&1
	rm version
fi

if [ "$recoveryimg" ]; then
	cd $TMPDIR
	for i in $recoveryimg
	do
		model=${i%-recovery.img}
		mv $i recovery.img
		tar -cf twrp-$TWRP_VER-$CDATE-$model.tar recovery.img
		cp twrp-$TWRP_VER-$CDATE-$model.tar ~/HostPC/Kernel/twrp-$TWRP_VER-$CDATE-$model.tar
		mv recovery.img $i
	done
	tar -cf recovery.tar *recovery.img
	xz -z -9 recovery.tar
	mv recovery.tar.xz ~/HostPC/Kernel/recovery.tar.xz
fi

echo ""
wait_device recovery
adb shell "rm /data/stock_boot*.img*"
echo "* push $KERNEL_NAME to device..."
adb push ~/HostPC/Kernel/out/$KERNEL_NAME /external_sd/CWM/test/$KERNEL_NAME

cd $CDIR
rm $TMPDIR/* 2> /dev/null

echo ""
echo "------------------------   DONE!!   ----------------------------"
echo ""

