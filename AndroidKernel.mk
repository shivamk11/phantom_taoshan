#Android makefile to build kernel as a part of Android Build
PERL		= perl

ifeq ($(TARGET_PREBUILT_KERNEL),)

KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_CONFIG := $(KERNEL_OUT)/.config
TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/arm/boot/zImage
KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_MODULES_INSTALL := system
KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules
KERNEL_IMG=$(KERNEL_OUT)/arch/arm/boot/Image

MSM_ARCH ?= $(shell $(PERL) -e 'while (<>) {$$a = $$1 if /CONFIG_ARCH_((?:MSM|QSD)[a-zA-Z0-9]+)=y/; $$r = $$1 if /CONFIG_MSM_SOC_REV_(?!NONE)(\w+)=y/;} print lc("$$a$$r\n");' $(KERNEL_CONFIG))
KERNEL_USE_OF ?= $(shell $(PERL) -e '$$of = "n"; while (<>) { if (/CONFIG_USE_OF=y/) { $$of = "y"; break; } } print $$of;' kernel/arch/arm/configs/$(KERNEL_DEFCONFIG))

ifeq "$(KERNEL_USE_OF)" "y"
DTS_NAME ?= $(MSM_ARCH)
DTS_FILES = $(wildcard $(TOP)/kernel/arch/arm/boot/dts/$(DTS_NAME)*.dts)
DTS_FILE = $(lastword $(subst /, ,$(1)))
DTB_FILE = $(addprefix $(KERNEL_OUT)/arch/arm/boot/,$(patsubst %.dts,%.dtb,$(call DTS_FILE,$(1))))
ZIMG_FILE = $(addprefix $(KERNEL_OUT)/arch/arm/boot/,$(patsubst %.dts,%-zImage,$(call DTS_FILE,$(1))))
KERNEL_ZIMG = $(KERNEL_OUT)/arch/arm/boot/zImage
DTC = $(KERNEL_OUT)/scripts/dtc/dtc

define append-dtb
mkdir -p $(KERNEL_OUT)/arch/arm/boot;\
$(foreach d, $(DTS_FILES), \
   $(DTC) -p 1024 -O dtb -o $(call DTB_FILE,$(d)) $(d); \
   cat $(KERNEL_ZIMG) $(call DTB_FILE,$(d)) > $(call ZIMG_FILE,$(d));)
endef
else

define append-dtb
endef
endif

#[SA77] ==> CCI KLog, added by Jimmy@CCI
ifeq ($(CCI_TARGET_KLOG),true)
  CCI_CUSTOMIZE := 1
  CCI_KLOG := 1
  CCI_KLOG_START_ADDR_PHYSICAL := $(CCI_TARGET_KLOG_START_ADDR_PHYSICAL)
  CCI_KLOG_SIZE := $(CCI_TARGET_KLOG_SIZE)
  CCI_KLOG_HEADER_SIZE := $(CCI_TARGET_KLOG_HEADER_SIZE)
  CCI_KLOG_CRASH_SIZE := $(CCI_TARGET_KLOG_CRASH_SIZE)
  CCI_KLOG_APPSBL_SIZE := $(CCI_TARGET_KLOG_APPSBL_SIZE)
  CCI_KLOG_KERNEL_SIZE := $(CCI_TARGET_KLOG_KERNEL_SIZE)
  CCI_KLOG_ANDROID_MAIN_SIZE := $(CCI_TARGET_KLOG_ANDROID_MAIN_SIZE)
  CCI_KLOG_ANDROID_SYSTEM_SIZE := $(CCI_TARGET_KLOG_ANDROID_SYSTEM_SIZE)
  CCI_KLOG_ANDROID_RADIO_SIZE := $(CCI_TARGET_KLOG_ANDROID_RADIO_SIZE)
  CCI_KLOG_ANDROID_EVENTS_SIZE := $(CCI_TARGET_KLOG_ANDROID_EVENTS_SIZE)
ifeq ($(CCI_TARGET_KLOG_SUPPORT_CCI_ENGMODE),true)
  CCI_KLOG_SUPPORT_CCI_ENGMODE := 1
endif # ifeq ($(CCI_TARGET_KLOG_SUPPORT_CCI_ENGMODE),true)
ifneq ($(TARGET_BUILD_VARIANT),user)
  CCI_KLOG_ALLOW_FORCE_PANIC := 1
endif # ifneq ($(TARGET_BUILD_VARIANT),user)
endif # ifeq ($(CCI_TARGET_KLOG),true)
#[SA77] <== CCI KLog, added by Jimmy@CCI

#[SA77] ==> For H/W key call panic, added by Aaron@CCI
ifneq ($(TARGET_BUILD_VARIANT),user)
  CCI_HWKEY_ALLOW_FORCE_PANIC := 1
endif# ifneq ($(TARGET_BUILD_VARIANT),user)

ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
$(info Using uncompressed kernel)
TARGET_PREBUILT_KERNEL := $(KERNEL_OUT)/piggy
else
TARGET_PREBUILT_KERNEL := $(TARGET_PREBUILT_INT_KERNEL)
endif

define mv-modules
mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`;\
ko=`find $$mpath/kernel -type f -name *.ko`;\
for i in $$ko; do mv $$i $(KERNEL_MODULES_OUT)/; done;\
fi
endef

define clean-module-folder
mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`; rm -rf $$mpath;\
fi
endef

$(KERNEL_OUT):
	mkdir -p $(KERNEL_OUT)

$(KERNEL_CONFIG): $(KERNEL_OUT)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- $(KERNEL_DEFCONFIG)

$(KERNEL_OUT)/piggy : $(TARGET_PREBUILT_INT_KERNEL)
	$(hide) gunzip -c $(KERNEL_OUT)/arch/arm/boot/compressed/piggy.gzip > $(KERNEL_OUT)/piggy

#[SA77] ==> Only enable UART with eng-build, added by Jimmy@CCI
#$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
$(TARGET_PREBUILT_INT_KERNEL): CONFIG_SECURE $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
#[SA77] <== Only enable UART with eng-build, added by Jimmy@CCI
#[SA77] ==> CCI KLog, added by Jimmy@CCI
ifeq ($(CCI_CUSTOMIZE),1)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- CCI_KLOG=$(CCI_KLOG) CCI_KLOG_START_ADDR_PHYSICAL=$(CCI_KLOG_START_ADDR_PHYSICAL) CCI_KLOG_SIZE=$(CCI_KLOG_SIZE) CCI_KLOG_HEADER_SIZE=$(CCI_KLOG_HEADER_SIZE) CCI_KLOG_CRASH_SIZE=$(CCI_KLOG_CRASH_SIZE) CCI_KLOG_APPSBL_SIZE=$(CCI_KLOG_APPSBL_SIZE) CCI_KLOG_KERNEL_SIZE=$(CCI_KLOG_KERNEL_SIZE) CCI_KLOG_ANDROID_MAIN_SIZE=$(CCI_KLOG_ANDROID_MAIN_SIZE) CCI_KLOG_ANDROID_SYSTEM_SIZE=$(CCI_KLOG_ANDROID_SYSTEM_SIZE) CCI_KLOG_ANDROID_RADIO_SIZE=$(CCI_KLOG_ANDROID_RADIO_SIZE) CCI_KLOG_ANDROID_EVENTS_SIZE=$(CCI_KLOG_ANDROID_EVENTS_SIZE) CCI_KLOG_SUPPORT_CCI_ENGMODE=$(CCI_KLOG_SUPPORT_CCI_ENGMODE) CCI_KLOG_ALLOW_FORCE_PANIC=$(CCI_KLOG_ALLOW_FORCE_PANIC) CCI_HWKEY_ALLOW_FORCE_PANIC=$(CCI_HWKEY_ALLOW_FORCE_PANIC)
else # ifeq ($(CCI_CUSTOMIZE),1)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi-
endif # ifeq ($(CCI_CUSTOMIZE),1)
#[SA77] <== CCI KLog, added by Jimmy@CCI
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- modules
	$(MAKE) -C kernel O=../$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) INSTALL_MOD_STRIP=1 ARCH=arm CROSS_COMPILE=arm-eabi- modules_install
	$(mv-modules)
	$(clean-module-folder)
	$(append-dtb)

$(KERNEL_HEADERS_INSTALL): $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- headers_install

kerneltags: $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- tags

kernelconfig: $(KERNEL_OUT) $(KERNEL_CONFIG)
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- menuconfig
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- savedefconfig
	cp $(KERNEL_OUT)/defconfig kernel/arch/arm/configs/$(KERNEL_DEFCONFIG)

#[SA77] ==> Only enable UART in eng-build, disable some debug options in user-build, added by Jimmy@CCI
KERNEL_DEFCONFIG_FILE := kernel/arch/arm/configs/$(KERNEL_DEFCONFIG)

CONFIG_SECURE:
ifeq ($(CCI_SECURE_MODE),true)
	echo "$(KERNEL_DEFCONFIG): set CONFIG_CCI_SECURE_MODE"
	sed -i '/SERIAL_MSM_HSL/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_SERIAL_MSM_HSL is not set" >> $(KERNEL_DEFCONFIG_FILE)
else
	echo "$(KERNEL_DEFCONFIG): unset CONFIG_CCI_SECURE_MODE"
	sed -i '/SERIAL_MSM_HSL/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_SERIAL_MSM_HSL=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/SERIAL_MSM_HSL_CONSOLE/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_SERIAL_MSM_HSL_CONSOLE=y" >> $(KERNEL_DEFCONFIG_FILE)
endif
ifeq ($(TARGET_BUILD_VARIANT),user)
	sed -i '/MSM_QDSS/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_MSM_QDSS is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_JTAG/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_MSM_JTAG is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_CACHE_ERP/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_CACHE_ERP=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_L1_ERR_PANIC/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_L1_ERR_PANIC=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_L1_ERR_LOG/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_L1_ERR_LOG=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/INPUT_EVBUG/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_INPUT_EVBUG is not set" >> $(KERNEL_DEFCONFIG_FILE)
else
	sed -i '/MSM_QDSS/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_QDSS=y" >> $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_QDSS_ETM_DEFAULT_ENABLE=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_JTAG/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_JTAG=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_CACHE_ERP/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_CACHE_ERP=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_L1_ERR_PANIC/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_L1_ERR_PANIC=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_L1_ERR_LOG/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_L1_ERR_LOG=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_L2_ERP_PRINT_ACCESS_ERRORS/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_L2_ERP_PRINT_ACCESS_ERRORS=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MSM_L2_ERP_1BIT_PANIC/d' $(KERNEL_DEFCONFIG_FILE)
ifeq ($(TARGET_BUILD_VARIANT),userdebug)
	echo "# CONFIG_MSM_L2_ERP_1BIT_PANIC is not set" >> $(KERNEL_DEFCONFIG_FILE)
else
	echo "CONFIG_MSM_L2_ERP_1BIT_PANIC=y" >> $(KERNEL_DEFCONFIG_FILE)
endif
	sed -i '/MSM_L2_ERP_2BIT_PANIC/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MSM_L2_ERP_2BIT_PANIC=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/INPUT_EVBUG/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_INPUT_EVBUG=m" >> $(KERNEL_DEFCONFIG_FILE)
endif
ifeq ($(TARGET_BUILD_VARIANT),user)
	sed -i '/DEBUG_MUTEXES/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_DEBUG_MUTEXES is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_DEBUG_PAGEALLOC/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_DEBUG_PAGEALLOC is not set" >> $(KERNEL_DEFCONFIG_FILE)
else
	sed -i '/DEBUG_MUTEXES/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_MUTEXES=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_DEBUG_PAGEALLOC/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_PAGEALLOC=y" >> $(KERNEL_DEFCONFIG_FILE)
endif
ifeq ($(TARGET_BUILD_VARIANT),user)
	sed -i '/CGROUP_DEBUG/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_CGROUP_DEBUG is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/SLUB_DEBUG/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_SLUB_DEBUG is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MMC_BLOCK_TEST/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_MMC_BLOCK_TEST is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_KMEMLEAK/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_DEBUG_KMEMLEAK is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_SPINLOCK/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_DEBUG_SPINLOCK is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_ATOMIC_SLEEP/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_DEBUG_ATOMIC_SLEEP is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_STACK_USAGE/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_DEBUG_STACK_USAGE is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_LIST/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_DEBUG_LIST is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/FAULT_INJECTION/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_FAULT_INJECTION is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_LOCKUP_DETECTOR/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_LOCKUP_DETECTOR is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/RCU_CPU_STALL_VERBOSE/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_RCU_CPU_STALL_VERBOSE is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/EVENT_POWER_TRACING_DEPRECATED/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_EVENT_POWER_TRACING_DEPRECATED is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_STACKTRACE=\|CONFIG_STACKTRACE /d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_STACKTRACE is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DETECT_HUNG_TASK/d' $(KERNEL_DEFCONFIG_FILE)
	echo "# CONFIG_DETECT_HUNG_TASK is not set" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_DEBUG_FS/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_FS=y" >> $(KERNEL_DEFCONFIG_FILE)
else
	sed -i '/PAGE_POISONING/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_PAGE_POISONING=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_TRACEPOINTS/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_TRACEPOINTS=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/NOP_TRACER/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_NOP_TRACER=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/EVENT_TRACING/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_EVENT_TRACING=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONTEXT_SWITCH_TRACER/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_CONTEXT_SWITCH_TRACER=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_TRACING=\|CONFIG_TRACING /d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_TRACING=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CGROUP_DEBUG/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_CGROUP_DEBUG=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_SLUB_DEBUG=\|CONFIG_SLUB_DEBUG /d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_SLUB_DEBUG=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/MMC_BLOCK_TEST/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_MMC_BLOCK_TEST=m" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_KMEMLEAK/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_KMEMLEAK=y" >> $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_KMEMLEAK_EARLY_LOG_SIZE=400" >> $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_KMEMLEAK_DEFAULT_OFF=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_SPINLOCK/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_SPINLOCK=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_ATOMIC_SLEEP/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_ATOMIC_SLEEP=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_STACK_USAGE/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_STACK_USAGE=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEBUG_LIST/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_LIST=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_FAULT_INJECTION/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_FAULT_INJECTION=y" >> $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_FAULT_INJECTION_DEBUG_FS=y" >> $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_FAULT_INJECTION_STACKTRACE_FILTER=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/FAILSLAB/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_FAILSLAB=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/FAIL_PAGE_ALLOC/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_FAIL_PAGE_ALLOC=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_LOCKUP_DETECTOR/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_LOCKUP_DETECTOR=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/RCU_CPU_STALL_VERBOSE/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_RCU_CPU_STALL_VERBOSE=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/ENABLE_DEFAULT_TRACERS/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_ENABLE_DEFAULT_TRACERS=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/BRANCH_PROFILE_NONE/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_BRANCH_PROFILE_NONE=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/KPROBE_EVENT/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_KPROBE_EVENT=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/EVENT_POWER_TRACING_DEPRECATED/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_EVENT_POWER_TRACING_DEPRECATED=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_STACKTRACE=\|CONFIG_STACKTRACE /d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_STACKTRACE=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DETECT_HUNG_TASK/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DETECT_HUNG_TASK=y" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/DEFAULT_HUNG_TASK_TIMEOUT/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEFAULT_HUNG_TASK_TIMEOUT=120" >> $(KERNEL_DEFCONFIG_FILE)
	sed -i '/CONFIG_DEBUG_FS/d' $(KERNEL_DEFCONFIG_FILE)
	echo "CONFIG_DEBUG_FS=y" >> $(KERNEL_DEFCONFIG_FILE)
endif
#[SA77] <== Only enable UART in eng-build, disable some debug options in user-build, added by Jimmy@CCI

endif
