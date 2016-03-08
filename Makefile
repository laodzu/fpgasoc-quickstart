.PHONY: dist ChangeLog rootfs-socrates.tar.gz

NFSPATH := /opt/socfpga/nfs/rootfs-socrates

all:	adjust-env.scr adjust-env u-boot-env.img ChangeLog

dist:	ChangeLog
	rm -f *~
	D=$(shell basename $$(pwd)) ; tar -C .. -zcv --exclude-vcs -f /tmp/$${D}.tgz $${D}

adjust-env.scr:	adjust-env
	mkimage -T script -C none -n 'Reset Environment' -d $< $@

adjust-env:	environment.txt
	echo "echo Reset environment" > $@
	sed "s/^\([^=]\+\)=\(.*\)$$/setenv \1 '\2'/g" $< >> $@

u-boot-env.img:	environment.txt
	if ! ./mkenvimage -V > /dev/null ; then \
	        echo "Cannot use provided mkenvimage - please compile it for your platform from U-Boot source tree" ;\
	else \
		./mkenvimage -p 0 -s 4096 -o $@ $< ; \
	fi

ChangeLog:
	git log > $@

rootfs-socrates.tar.gz:
	TMP=`mktemp` ; sudo tar -C $(NFSPATH) -czf $$TMP . ; mv $$TMP $@
