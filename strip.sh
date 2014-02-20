
PATH=/home/shivam/development/toolchains/arm-eabi-4.7/bin:$PATH
cd ../
export PATH
#Build kernel
arm-eabi-strip --strip-unneeded kernel/arch/arm/mach-msm/reset_modem.ko
arm-eabi-strip --strip-unneeded kernel/arch/arm/mach-msm/msm-buspm-dev.ko
arm-eabi-strip --strip-unneeded kernel/fs/nls/nls_utf8.ko
arm-eabi-strip --strip-unneeded kernel/fs/cifs/cifs.ko
arm-eabi-strip --strip-unneeded kernel/fs/ntfs/ntfs.ko
arm-eabi-strip --strip-unneeded kernel/fs/fuse/fuse.ko
arm-eabi-strip --strip-unneeded kernel/crypto/ansi_cprng.ko
arm-eabi-strip --strip-unneeded kernel/drivers/video/backlight/lcd.ko
arm-eabi-strip --strip-unneeded kernel/drivers/char/adsprpc.ko
arm-eabi-strip --strip-unneeded kernel/drivers/misc/eeprom/eeprom_93cx6.ko
arm-eabi-strip --strip-unneeded kernel/drivers/scsi/scsi_wait_scan.ko
arm-eabi-strip --strip-unneeded kernel/drivers/spi/spidev.ko
arm-eabi-strip --strip-unneeded kernel/drivers/net/ethernet/micrel/ks8851.ko
arm-eabi-strip --strip-unneeded kernel/drivers/net/tun.ko
arm-eabi-strip --strip-unneeded kernel/drivers/input/evbug.ko
arm-eabi-strip --strip-unneeded kernel/drivers/media/video/gspca/gspca_main.ko
arm-eabi-strip --strip-unneeded kernel/drivers/media/radio/radio-iris-transport.ko
arm-eabi-strip --strip-unneeded kernel/drivers/crypto/msm/qcedev.ko
arm-eabi-strip --strip-unneeded kernel/drivers/crypto/msm/qce40.ko
arm-eabi-strip --strip-unneeded kernel/drivers/crypto/msm/qcrypto.ko
arm-eabi-strip --strip-unneeded kernel/drivers/hid/hid-sony.ko
arm-eabi-strip --strip-unneeded kernel/drivers/staging/prima/wlan.ko
arm-eabi-strip --strip-unneeded kernel/drivers/coresight/control_trace.ko
arm-eabi-strip --strip-unneeded kernel/drivers/gud/mckernelapi.ko
arm-eabi-strip --strip-unneeded kernel/drivers/gud/mcdrvmodule.ko
arm-eabi-strip --strip-unneeded kernel/net/l2tp/l2tp_core.ko
arm-eabi-strip --strip-unneeded kernel/net/l2tp/l2tp_ppp.ko
cd kernel

