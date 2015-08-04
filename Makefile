.PHONY: dist

dist:	adjust-env.scr adjust-env u-boot-env.img
	rm -f *~
	( D=$(shell basename $$(pwd)) ; cd .. ; tar -zcv --exclude-vcs -f /tmp/$${D}.tgz $${D} )

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
