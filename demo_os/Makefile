ifeq ($(OS),Windows_NT)
ASPREFIX=
else
ASPREFIX=mono 
endif
AS=$(ASPREFIX)build/sass.exe
INCLUDE=inc/
.DEFAULT_GOAL=TI84pSE

all:
	make TI73
	make TI83p
	make TI83pSE
	make TI84p
	make TI84pSE
	make TI84pCSE

TI73: PLATFORM := TI73
TI73: PRIVILEGED := 70000
TI73: BOOT := 7C000
TI73: LENGTH := 80000
TI73: directories system

TI83p: PLATFORM := TI83p
TI83p: PRIVILEGED := 70000
TI83p: BOOT := 7C000
TI83p: LENGTH := 80000
TI83p: directories system

TI83pSE: PLATFORM := TI83pSE
TI83pSE: PRIVILEGED := 1F0000
TI83pSE: BOOT := 1FC000
TI83pSE: LENGTH := 200000
TI83pSE: directories system

TI84p: PLATFORM := TI84p
TI84p: PRIVILEGED := F0000
TI84p: BOOT := FC000
TI84p: LENGTH := 100000
TI84p: directories system

TI84pSE: PLATFORM := TI84pSE
TI84pSE: PRIVILEGED := 1F0000
TI84pSE: BOOT := 1FC000
TI84pSE: LENGTH := 200000
TI84pSE: directories system

TI84pCSE: PLATFORM := TI84pCSE
TI84pCSE: PRIVILEGED := 3F0000
TI84pCSE: BOOT := 3FC000
TI84pCSE: LENGTH := 400000
TI84pCSE: directories system

DEFINES=$(PLATFORM)

system: page00 pageBoot #pagePrivledged
	$(ASPREFIX)build/MakeROM.exe bin/$(PLATFORM).rom $(LENGTH) bin/00.bin:0 bin/boot.bin:$(BOOT)
	rm bin/00.bin
	rm bin/boot.bin

page00:
	$(AS) $(ASFLAGS) --define "$(DEFINES)" --include "$(INCLUDE);src/00/" src/00/base.asm bin/00.bin --listing bin/00.list

pageBoot:
	$(AS) $(ASFLAGS) --define "$(DEFINES)" --include "$(INCLUDE);src/boot/" src/boot/base.asm bin/boot.bin --listing bin/boot.list

directories:
	mkdir -p bin

clean:
	rm -r bin
