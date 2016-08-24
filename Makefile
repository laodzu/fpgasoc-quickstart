.PHONY: dist ChangeLog rootfs-socrates.tar.gz

NFSPATH := /opt/socfpga/nfs/rootfs-socrates
ROOTFSGITPATH := /opt/git/rootfs-socrates

ifneq ($(shell ls -d .git 2>/dev/null),)
INSIDEGIT := y
endif

DIR := $(shell basename $$(pwd))
ifeq ($(INSIDEGIT),y)
TAR := $(shell basename $$(pwd))-g$(shell git log --format=oneline HEAD^! | cut -c1-7).tgz
else
TAR := $(shell basename $$(pwd)).tgz
endif

# See if we can successfully execute the binary mkenvimage
ifeq ($(strip $(shell ./mkenvimage -V 2>&1 > /dev/null)),)
HAVEMKENVIMAGE := y
endif

all:	adjust-env.scr adjust-env u-boot-env.img ChangeLog

dist:	ChangeLog
	rm -f *~
	tar -C .. -zcv --exclude-vcs -f /tmp/$(TAR) $(DIR)

adjust-env.scr:	adjust-env
	mkimage -T script -C none -n 'Reset Environment' -d $< $@

adjust-env:	environment.txt
	echo "echo Reset environment" > $@
	sed "s/^\([^=]\+\)=\(.*\)$$/setenv \1 '\2'/g" $< >> $@

u-boot-env.img:	environment.txt
ifeq ($(HAVEMKENVIMAGE),y)
	./mkenvimage -p 0 -s 4096 -o $@ $<
else
	$(error Cannot use provided mkenvimage - please compile it for your platform from U-Boot source tree)
endif

ChangeLog:
ifeq ($(INSIDEGIT),y)
	git log > $@
else
	$(warning Warning: Not running from git - $@ will not be updated)
endif

rootfs-socrates.tar.gz:
	TMP=`mktemp` ; \
	sudo tar -C $(NFSPATH) --exclude=.ssh/authorized_keys \
	  --exclude=.ssh/known_hosts -czf $$TMP . ; \
	mv $$TMP $@
	git --git-dir $(ROOTFSGITPATH) log > ChangeLog.rootfs
