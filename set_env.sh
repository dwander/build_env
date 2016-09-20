#!/bin/bash

export ARCH=arm
export CROSS_COMPILE=/home/dq/dev/arm-eabi-5.4.1/bin/arm-eabi-

TMPDIR=~/env/build-files/tmp
CDATE=$(date +"%Y%m%d")
CDIR=$PWD
DEVICE="N4"
KERNEL_VERSION=$(grep -m 1 "CONFIG_LOCALVERSION" .config | sed s/\"//g)
KERNEL_VERSION=$(echo $KERNEL_VERSION|sed "s/.*[-_v]//i")
KERNEL_NAME="PRIME-Kernel_${DEVICE}_v${KERNEL_VERSION}.zip"

TWRP_VER="3.1.1-0"
RAMDISK_TW=~/env/ramdisk/tw
RAMDISK_CM=~/env/ramdisk/cm14
RAMDISK_TWRP=~/env/ramdisk/twrp
BUILD_VARIANTS="n916-tw n915-tw n910kor-tw n910ch-tw n910u-tw"
#BUILD_VARIANTS="n916-twrp n915-twrp n910-twrp"
#BUILD_VARIANTS="n916-tw n916-twrp n915-tw n915-twrp n910-tw n910-twrp"

magisk="/external_sd/CWM/Magisk/Magisk-v14.0.zip"

mkdir $RAMDISK_TW/data 2>/dev/null
mkdir $RAMDISK_TW/dev 2>/dev/null
mkdir $RAMDISK_TW/lib 2>/dev/null
mkdir $RAMDISK_TW/lib/modules 2>/dev/null
mkdir $RAMDISK_TW/proc 2>/dev/null
mkdir $RAMDISK_TW/sys 2>/dev/null

# echo "RAMDISK: $RAMDISK_TW"

function config()
{
	local TAG=$1
	local VAL=$2
	local FILE=".config"
	local AVAIL=0
	local IS_NOT_SET=$(grep -m1 -c "# $TAG is not set" $FILE)

	if [ $IS_NOT_SET -eq 1 ] || [ $(grep -m1 -c "^$TAG=" $FILE) -eq 1 ]; then
		AVAIL=1
	fi
	if [ $(echo $VAL|grep -c " ") -eq 1 ]; then
		$VAL="\"$VAL\""
	fi

	if [ $AVAIL -eq 1 ];	then
		if [ $VAL == "-" ]; then
			sed -i -e "/# $TAG is not set/d" $FILE
			sed -i -e "/^$TAG=.*/d" $FILE
		elif [ $VAL == "n" ]; then
			sed -i -e "s/$TAG=.*/# $TAG is not set/g" $FILE
		else
			sed -i -e "s/$TAG=.*/$TAG=$VAL/g" $FILE
			sed -i -e "s/# $TAG is not set/$TAG=$VAL/g" $FILE
		fi
	elif [ $VAL != "-" ]; then
		if [ $VAL == "n" ]; then
			echo "# $TAG is not set" >> $FILE
		else
			echo "$TAG=$VAL" >> $FILE
		fi
	fi
}

function mtp_sec() {
    config CONFIG_USB_ANDROID_SAMSUNG_MTP y
}
function mtp_nosec() {
    config CONFIG_USB_ANDROID_SAMSUNG_MTP n
}

function n910c() {
	patch -p1 < ~/env/n910c.patch
}

function n910k() {
	patch -p1 -R < ~/env/n910c.patch
}

function ss300(){
    config CONFIG_UMTS_MODEM_SS333 n
    config CONFIG_UMTS_MODEM_SS300 y
    config CONFIG_SENSORHUB_S333 n
    sed -i -e "s/import init.baseband-n916.rc/import init.baseband-n910k.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n915.rc/import init.baseband-n910k.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n910ch.rc/import init.baseband-n910k.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n910u.rc/import init.baseband-n910k.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    config CONFIG_LINK_DEVICE_SPI n
}

function ss333(){
    config CONFIG_UMTS_MODEM_SS300 n
    config CONFIG_UMTS_MODEM_SS333 y
    config CONFIG_SENSORHUB_S333 y
    sed -i -e "s/import init.baseband-n910k.rc/import init.baseband-n916.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n915.rc/import init.baseband-n916.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n910ch.rc/import init.baseband-n916.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n910u.rc/import init.baseband-n916.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    config CONFIG_LINK_DEVICE_SPI y
}

function m7400(){
    sed -i -e "s/import init.baseband-n916.rc/import init.baseband-n910ch.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n915.rc/import init.baseband-n910ch.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n910k.rc/import init.baseband-n910ch.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n910u.rc/import init.baseband-n910ch.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
}

function m72xx(){
    sed -i -e "s/import init.baseband-n916.rc/import init.baseband-n910u.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n915.rc/import init.baseband-n910u.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n910k.rc/import init.baseband-n910u.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
    sed -i -e "s/import init.baseband-n910ch.rc/import init.baseband-n910u.rc/g" $RAMDISK_TW/init.universal5433.rc 2>/dev/null
}

function flat(){
    config CONFIG_SENSORS_SSP_LPS25H n
    config CONFIG_LCD_ALPM n
    config CONFIG_DECON_LCD_S6E3HF2 n
    config CONFIG_CAMERA_TBE n
    config CONFIG_CAMERA_TRE y
    config CONFIG_KEYBOARD_CYPRESS_TOUCH_MBR31X5 y
    config CONFIG_DECON_LCD_S6E3HA2 y
    config CONFIG_SND_SAMSUNG_COMPENSATE_EXT_RES y
    config CONFIG_SENSORS_SSP_BMP182 y
}

function edge(){
    config CONFIG_SENSORS_SSP_LPS25H y
    config CONFIG_LCD_ALPM y
    config CONFIG_DECON_LCD_S6E3HF2 y
    config CONFIG_CAMERA_TBE y
    config CONFIG_CAMERA_TRE n
    config CONFIG_KEYBOARD_CYPRESS_TOUCH_MBR31X5 n
    config CONFIG_DECON_LCD_S6E3HA2 n
    config CONFIG_SND_SAMSUNG_COMPENSATE_EXT_RES n
    config CONFIG_SENSORS_SSP_BMP182 n
}

function mmc(){
    config CONFIG_MMC_DW_BYPASS_FMP y
    config CONFIG_MMC_DW_FMP_DM_CRYPT n
}

function ufs1(){
    config CONFIG_MMC_DW_BYPASS_FMP n
    config CONFIG_MMC_DW_FMP_DM_CRYPT y
}

function clean(){
	find ./drivers/sensorhub -name '*.o' -exec rm {} \;
	find ./drivers/misc/modem_v1 -name '*.o' -exec rm {} \;
}

function cleardir() {
    CDIR=$PWD
    cd $1

    find . -type f \( -iname \*.rej \
                    -o -iname \*.orig \
                    -o -iname \*.bkp \
                    -o -iname \*.ko \
                    -o -iname \*.c.BACKUP.[0-9]*.c \
                    -o -iname \*.c.BASE.[0-9]*.c \
                    -o -iname \*.c.LOCAL.[0-9]*.c \
                    -o -iname \*.c.REMOTE.[0-9]*.c \
                    -o -iname \*.org \
                    -o -iname \*.old \) \
                        | parallel --no-notice rm -fv {};

    rm -rf tmp/* > /dev/null 2>&1
    rm Module.symvers > /dev/null 2>&1
    rm .version > /dev/null 2>&1
    rm -R ./include/config > /dev/null 2>&1
    rm -R ./include/generated > /dev/null 2>&1
    rm -R ./arch/arm/include/generated > /dev/null 2>&1

    cd $CDIR
    chmod 644 $1/file_contexts > /dev/null 2>&1
    chmod 644 $1/se* > /dev/null 2>&1
    chmod 644 $1/*.rc > /dev/null 2>&1
    chmod 750 $1/init* > /dev/null 2>&1
    chmod 640 $1/fstab* > /dev/null 2>&1
    chmod 644 $1/default.prop > /dev/null 2>&1
    chmod 771 $1/data > /dev/null 2>&1
    chmod 755 $1/dev > /dev/null 2>&1
    chmod 755 $1/proc > /dev/null 2>&1
    chmod 750 $1/sbin > /dev/null 2>&1
    chmod 750 $1/sbin/* > /dev/null 2>&1
    chmod 755 $1/res > /dev/null 2>&1
    chmod 755 $1/res/* > /dev/null 2>&1
    chmod 755 $1/res/bin > /dev/null 2>&1
    chmod 755 $1/res/bin/* > /dev/null 2>&1
    chmod 755 $1/sys > /dev/null 2>&1
    chmod 755 $1/system > /dev/null 2>&1
}
