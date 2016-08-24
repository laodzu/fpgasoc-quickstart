.PHONY: dist ChangeLog rootfs-socrates.tar.gz

NFSPATH := /opt/socfpga/nfs/rootfs-socrates
ROOTFSGITPATH := /opt/git/rootfs-socrates

all:	adjust-env.scr adjust-env u-boot-env.img ChangeLog

dist:	ChangeLog
	rm -f *~
	D=$(shell basename $$(pwd)); \
	if [ -d .git ] ; then \
		TAR="$${D}-g`git log --format=oneline HEAD^! | cut -c1-7`.tgz" ; \
	else \
		TAR=$${D}.tgz ; \
	fi ;\
	tar -C .. -zcv --exclude-vcs -f /tmp/$${TAR} $${D}

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
	if [ -d .git ]; then \
		git log > $@ ; \
	else \
		echo "Not running from git - cannot regenerate $@" ; \
	fi

rootfs-socrates.tar.gz:
	TMP=`mktemp` ; \
	sudo tar -C $(NFSPATH) --exclude=.ssh/authorized_keys \
	  --exclude=.ssh/known_hosts -czf $$TMP . ; \
	mv $$TMP $@
	git --git-dir $(ROOTFSGITPATH) log > ChangeLog.rootfs
