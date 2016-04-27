OLDLOC              := /usr/local/gcc-arm-none-eabi-4_9-2015q1
NEWLOC              := $(shell pwd)/gcc-arm-none-eabi-4_9-2015q3
MKPOSIX             := sdk/components/toolchain/gcc/Makefile.posix
SDK_ZIPFILE         := nRF5_SDK_11.0.0_89a8197.zip
TOOLCHAIN_TARBALL   := gcc-arm-none-eabi-4_9-2015q3-20150921-linux.tar.bz2
NRF5X_TOOLS_TARBALL := nRF5x-Command-Line-Tools_8_4_0_Linux-x86_64.tar
BLINKY_ARMGCC       := sdk/examples/peripheral/blinky/pca10040/blank/armgcc

default: gcc-arm-none-eabi-4_9-2015q3/.done sdk/.done \
         nrfjprog/.done /opt/SEGGER/JLink/libjlinkarm.so

gcc-arm-none-eabi-4_9-2015q3/.done: $(TOOLCHAIN_TARBALL)
	tar xjf $+
	touch $@

$(TOOLCHAIN_TARBALL):
	wget https://launchpad.net/gcc-arm-embedded/4.9/4.9-2015-q3-update/+download/$@

$(SDK_ZIPFILE):
	wget http://developer.nordicsemi.com/nRF5_SDK/nRF5_SDK_v11.x.x/$@

sdk/.done: $(SDK_ZIPFILE)
	mkdir sdk
	cd sdk && unzip ../$+
	grep $(OLDLOC) $(MKPOSIX) && sed -i "s|$(OLDLOC)|$(NEWLOC)|g" $(MKPOSIX)
	touch $@

$(NRF5X_TOOLS_TARBALL):
	wget -O $@ https://www.nordicsemi.com/eng/nordic/download_resource/51392/12/22403371

nrfjprog/.done: $(NRF5X_TOOLS_TARBALL)
	tar xf $+
	touch $@

JLinkDebugger_Linux_V214h_x86_64.tgz:
	wget https://download.segger.com/J-Link/J-LinkDebugger/$@

JLinkDebugger_Linux_V214h_x86_64/.done: JLinkDebugger_Linux_V214h_x86_64.tgz
	tar zxf $+
	touch $@

/opt/SEGGER/JLink/libjlinkarm.so: JLinkDebugger_Linux_V214h_x86_64/.done
	sudo mkdir -p /opt/SEGGER/JLink
	sudo cp JLinkDebugger_Linux_V214h_x86_64/Lib/libjlinkarm.so /opt/SEGGER/JLink/

blinky: default
	$(MAKE) -C $(BLINKY_ARMGCC)

deploy_blinky: blinky
	./nrfjprog/nrfjprog  --family nRF52 -e
	./nrfjprog/nrfjprog  --family nRF52 --program $(BLINKY_ARMGCC)/_build/nrf52832_xxaa.hex
	./nrfjprog/nrfjprog  --family nRF52 -r

check: blinky_blank_pca10040

cleanall:
	rm -rf sdk/ nrfjprog/ mergehex/ gcc-arm-none-eabi-4_9-2015q3/ JLinkDebugger_Linux_V214h_x86_64/

distclean: cleanall
	rm -f $(TOOLCHAIN_TARBALL) $(SDK_ZIPFILE) $(NRF5X_TOOLS_TARBALL)

.PHONY: default check cleanall blinky deploy_blinky
