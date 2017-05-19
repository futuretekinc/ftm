TOPDIR=${CURDIR}

export TOPDIR

include Makefile.in

phase1-y= 
#phase1-${CONFIG_GMP} += gmp
#phase1-${CONFIG_PCRE} += pcre 
#phase1-${CONFIG_LIBUBOX} += libubox 
#phase1-${CONFIG_ZLIB} += zlib 
#phase1-${CONFIG_QDECODER} += qdecoder 
#phase1-${CONFIG_LIBPCAP} += libpcap
#phase1-${CONFIG_LIBCONFIG} += libconfig
#phase1-${CONFIG_LIBMODBUS} += libmodbus
#phase1-${CONFIG_LIBUUID} += libuuid
#phase1-${CONFIG_LIBESTR} += libestr
phase1-${CONFIG_LIBXML2} += libxml2
#phase1-${CONFIG_OPENSSL} += openssl 
#phase1-${CONFIG_SQLITE} += sqlite
#phase1-${CONFIG_MXML} += mxml
#phase1-${CONFIG_CJSON} += cjson
#phase1-${CONFIG_CURL} += curl
#phase1-${CONFIG_NCURSES} += ncurses
#
#phase2-y=
#phase2-${CONFIG_BASE} += base 
#phase2-${CONFIG_BUSYBOX} += busybox 
#phase2-${CONFIG_CRON} += cron
#phase2-$(CONFIG_GPIO) += gpio
#phase2-${CONFIG_AZURE_SDK} += azure-iot-sdk
#
## Network Applications
#phase2-${CONFIG_NETWORK} += network 
#phase2-${CONFIG_IPTABLES} += iptables 
#phase2-${CONFIG_NET_SNMP} += net-snmp
#phase2-${CONFIG_OPENSSH} += openssh 
#phase2-${CONFIG_DROPBEAR} += dropbear 
#phase2-${CONFIG_STRONGSWAN} += strongswan 
#phase2-${CONFIG_HOTPLUG2} += hotplug2 
#phase2-${CONFIG_NTPCLIENT} += ntpclient 
#phase2-${CONFIG_HTTPD} += httpd 
#phase2-${CONFIG_LIGHTTPD} += lighttpd 
#phase2-${CONFIG_UDHCPD} += udhcpd
#phase2-${CONFIG_WEBADMIN} += webadmin 
#phase2-${CONFIG_MOSQUITTO} += mosquitto 
#phase2-${CONFIG_BIND} += bind
#phase2-${CONFIG_FTPD} += ftpd
#phase2-${CONFIG_FUTURESYSTEM_SSLVPN} += futuresystem_sslvpn
#phase2-${CONFIG_PYTHON} += python
#
## Wireless applications
#phase2-${CONFIG_WIRELESS_TOOLS} += wireless_tools 
#phase2-${CONFIG_WIFI} += wifi 
#phase2-${CONFIG_AP} += ap
#
## Daliworks Thingplus-Gateway
#phase2-${CONFIG_NODE} += node
#phase2-${CONFIG_TPGW} += tpgw
#
## Configuration Utilities
#phase2-${CONFIG_LUA} += lua 
#phase2-${CONFIG_UCI} += uci 
#
## Debugging Utilities
#phase2-${CONFIG_TCPDUMP} += tcpdump 
#
## Model
#phase2-${CONFIG_LGUPLUS} += lg-uplus
#phase2-${CONFIG_WIRED} += ${CONFIG_PLATFORM}-wired

LIBS=${phase1-y}
APPS=${phase2-y}

all: install_phase2
	
phase1: build_phase1

config_phase1: 
	[ -d ${BUILDDIR} ] || mkdir -p ${BUILDDIR}; 
	( \
		cd ${BUILDDIR}; \
		for lib in $(LIBS); do \
			${TOPDIR}/tools/app_config $$lib ${PKGDIR} ${DESTDIR};\
		done ; \
	) 

config_phase2: install_phase1
	[ -d ${BUILDDIR} ] || mkdir -p ${BUILDDIR}; 
	( \
		cd ${BUILDDIR}; \
		for app in $(APPS); do \
			${TOPDIR}/tools/app_config $$app ${PKGDIR} ${DESTDIR};\
		done; \
	)


build_phase1:  config_phase1
	( \
		cd ${BUILDDIR}; \
		for app in $(LIBS); do \
			make -C $$app build ; \
		done; \
	)

build_phase2:  config_phase2
	( \
		cd ${BUILDDIR}; \
		for app in $(APPS); do \
			make -C $$app build ; \
		done; \
	)

build: build_phase2

install_phase1: build_phase1
	if [ -d ${DESTDIR} ]; then \
		rm -rf ${DESTDIR}\* ;\
	else \
		mkdir -p ${DESTDIR} ;\
	fi
	( \
		cd ${BUILDDIR}; \
		for app in $(LIBS); do \
			make -C $$app install DESTDIR=${DESTDIR} ; \
		done; \
	)

install_phase2: build_phase2
	if [ -d ${DESTDIR} ]; then \
		rm -rf ${DESTDIR}\* ;\
	else \
		mkdir -p ${DESTDIR} ;\
	fi
	( \
		cd ${BUILDDIR}; \
		for app in $(APPS); do \
			make -C $$app install DESTDIR=${DESTDIR} ; \
		done; \
	)
	tools/create_rcd ${DESTDIR}
#	${TOPDIR}/tools/make_image ${DESTDIR} ${BUILDDIR}/rootfs.img

#	if [ -d ${DESTDIR} ]; then \
		rm -rf ${DESTDIR} ;\
	fi

ifneq ("$(APP)","")
config: FORCE
	[ -d ${BUILDDIR} ] || mkdir -p ${BUILDDIR}; 
	( \
		cd ${BUILDDIR}; \
		[ -d $(APP) ] || tar xvfz ${PKGDIR}/$(APP)-pkg.tar.gz ;\
		make -C $(APP) config DESTDIR=${DESTDIR} ; \
	)
else
config: install_phase1
	[ -d ${BUILDDIR} ] || mkdir -p ${BUILDDIR}; 
	( \
		cd ${BUILDDIR}; \
		for app in $(APPS); do \
			[ -d $$app ] || tar xvfz ${PKGDIR}/$$app-pkg.tar.gz ; \
			make -C $$app config DESTDIR=${DESTDIR} ; \
		done; \
	)
endif


FORCE:

install: install_phase2

.PHONY: image clean distclean


image:
	sudo mount /dev/sdb1 mmc
	sudo rm -rf mmc/*
	sudo tools/make_target mmc
	sudo tools/make_dev mmc
	sudo cp -r build/$(PLATFORM)/_root/* mmc/
	sudo cp -r mmc/etc/config/* mmc/etc/default/
	sudo umount mmc

clean:
	( \
		cd ${BUILDDIR}; \
		for app in $(LIBS) $(APPS); do \
			make -C $$app clean ; \
		done; \
	)

distclean:
	rm -rf ${BUILDDIR}

