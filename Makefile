# neutrino 2019 summer
# IIE CAS
# Please have a look at README.md first

CONFIG ?= DefaultKC705Config

### vivado source
defaultconfig_v = verilog/$(CONFIG).v 		#rocket-chip generated verilog
firmware_hex = verilog/firmware.hex 			#image of BRAM_64K

sdload_c = firmware/sdload.c

bootrom_img = rocket-chip/bootrom/bootrom.img 	#image of TLBootrom
bootrom_s = rocket-chip/bootrom/bootrom.S

vivado_source : bootrom_replace rocketconfig_replace dts_replace $(defaultconfig_v) $(firmware_hex)

bootrom_replace :
	cp firmware/TLBootrom/* rocket-chip/bootrom 
	@echo "#################################"
	@echo "#####  TLBootroom replaced  #####"
	@echo "#################################"

rocketconfig_replace :
	mv rocket-chip/src/main/scala/system/Configs.scala rocket-chip/src/main/scala/system/Configs.scala.old
	cp rocketconfig/system.Configs.scala rocket-chip/src/main/scala/system/Configs.scala
	mv rocket-chip/src/main/scala/subsystem/Configs.scala rocket-chip/src/main/scala/subsystem/Configs.scala.old
	cp rocketconfig/subsystem.Configs.scala rocket-chip/src/main/scala/subsystem/Configs.scala
	@echo "#################################"
	@echo "#### Configs.scala replaced #####"
	@echo "#################################"

dts_replace :
	mv riscv-pk/build/temporary_dtb.dts riscv-pk/build/temporary_dtb.dts.old
	cp firmware/mem1gb.dts riscv-pk/build/temporary_dtb.dts
	@echo "#################################"
	@echo "#####     dts replaced      #####"
	@echo "#################################"

$(defaultconfig_v) : $(bootrom_img)
	cd rocket-chip/vsim && CONFIG=$(CONFIG) $(MAKE) verilog && cp generated-src/freechips.rocketchip.system.$(CONFIG).v ../../verilog/DefaultConfig.v
	@echo "#################################"
	@echo "##### DefaultConfig.v built #####"
	@echo "#################################"

$(bootrom_img) : $(bootrom_s)
	cd rocket-chip/bootrom && $(MAKE)
	@echo "#################################"
	@echo "#####   Bootrom.img built   #####"
	@echo "#################################"

$(firmware_hex) : $(sdload_c)
	cd firmware && $(MAKE) all && cp firmware.hex ../verilog/firmware.hex
	@echo "#################################"
	@echo "#####  firmware.hex built   #####"
	@echo "#################################"


### sd_image
boot_elf = boot.elf 							#image stored in sd card, including bbl + kernel

sd_image : $(boot_elf)

$(boot_elf) : $(VMLINUX)
ifndef VMLINUX
	$(error Please set VMLINUX. Please take a look at README)
endif
	cd riscv-pk/build && $(MAKE) VMLINUX=$(VMLINUX) && cp bbl ../../boot.elf
	@echo "#################################"
	@echo "#####     boot.elf built    #####"
	@echo "#################################"

### clean
clean:
	cd rocket-chip/vsim && $(MAKE) clean
	cd firmware && $(MAKE) clean
	cd riscv-pk/build && $(MAKE) clean
	-rm $(defaultconfig_v)
	-rm $(firmware_hex)
	-rm $(boot_elf)
	-mv rocket-chip/src/main/scala/system/Configs.scala.old rocket-chip/src/main/scala/system/Configs.scala
	-mv rocket-chip/src/main/scala/subsystem/Configs.scala.old rocket-chip/src/main/scala/subsystem/Configs.scala
	-mv riscv-pk/build/temporary_dtb.dts.old riscv-pk/build/temporary_dtb.dts
