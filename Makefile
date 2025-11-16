TOOLCHAINNAME=arm-gnu-toolchain
TOOLCHAINVER=14.3.rel1
TOOLCHAINARCH=x86_64-arm-none-eabi
TOOLCHAINEXT=tar.xz
TOOLCHAINFILE=$(TOOLCHAINNAME)-$(TOOLCHAINVER)-$(TOOLCHAINARCH).$(TOOLCHAINEXT)
TOOLCHAINURL=https://developer.arm.com/-/media/Files/downloads/gnu/$(TOOLCHAINVER)/binrel/$(TOOLCHAINFILE)
TOOLCHAINDIRNAME=$(TOOLCHAINNAME)-$(TOOLCHAINVER)-$(TOOLCHAINARCH)
HOST=portal
DOMAIN=local
FQDN=${HOST}.${DOMAIN}
IP=192.168.1.4
PORTALURL=https://${FQDN}/
RUNPYENV = . bin/activate ; 
EXPORT = export PATH=$(shell pwd)/$(TOOLCHAINDIRNAME)/bin:$$PATH
MOUNTPCIR = $(shell mount | cut -f3 -d ' ' | sed -n '/CIRCUITPY$$/p')
MOUNTPRPI = $(shell mount | cut -f3 -d ' ' | sed -n '/RPI-RP2$$/p')

define patch_dhcpserver_file
@@ -57,6 +57,7 @@
 #define DHCP_OPT_DNS                (6)
 #define DHCP_OPT_HOST_NAME          (12)
 #define DHCP_OPT_REQUESTED_IP       (50)
+#define DHCP_OPT_DOMAIN_NAME        (15)
 #define DHCP_OPT_IP_LEASE_TIME      (51)
 #define DHCP_OPT_MSG_TYPE           (53)
 #define DHCP_OPT_SERVER_ID          (54)
@@ -64,6 +65,8 @@
 #define DHCP_OPT_MAX_MSG_SIZE       (57)
 #define DHCP_OPT_VENDOR_CLASS_ID    (60)
 #define DHCP_OPT_CLIENT_ID          (61)
+#define DHCP_OPT_CAPTIVE_PORTAL     (114)
+#define DHCP_OPT_CAPTIVE_PORTAL1    (160)
 #define DHCP_OPT_END                (255)

 #define PORT_DHCP_SERVER (67)
@@ -290,6 +293,10 @@
     opt_write_n(&opt, DHCP_OPT_ROUTER, 4, &ip_2_ip4(&d->ip)->addr); // aka gateway; can have multiple addresses
     opt_write_u32(&opt, DHCP_OPT_DNS, DEFAULT_DNS); // can have multiple addresses
     opt_write_u32(&opt, DHCP_OPT_IP_LEASE_TIME, DEFAULT_LEASE_TIME_S);
+    opt_write_n(&opt, DHCP_OPT_CAPTIVE_PORTAL,  $(shell echo -n $${#PORTALURL}), "${PORTALURL}");
+    opt_write_n(&opt, DHCP_OPT_CAPTIVE_PORTAL1, $(shell echo -n $${#PORTALURL}), "${PORTALURL}");
+    opt_write_n(&opt, DHCP_OPT_DOMAIN_NAME, 5, "local");
+    opt_write_n(&opt, DHCP_OPT_HOST_NAME,   6, "client");
     *opt++ = DHCP_OPT_END;
     struct netif *netif = ip_current_input_netif();
     dhcp_socket_sendto(&d->udp, netif, &dhcp_msg, opt - (uint8_t *)&dhcp_msg, 0xffffffff, PORT_DHCP_CLIENT);
endef

export

all: download makecert

download: $(TOOLCHAINDIRNAME) circuitpython pico-ducky flash_nuke.uf2


$(TOOLCHAINDIRNAME):
	curl -# -L $(TOOLCHAINURL) | tar --xz -xf -

circuitpython:
	git clone https://github.com/adafruit/circuitpython

pico-ducky:
	git clone https://github.com/dbisu/pico-ducky


flash_nuke.uf2:
	curl -LO https://datasheets.raspberrypi.com/soft/flash_nuke.uf2

makecert:
	openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=$(FQDN)" -addext "subjectAltName=DNS:$(FQDN)"

distclean:
	rm -rf $(TOOLCHAINDIRNAME) circuitpython pico-ducky cert.pem key.pem flash_nuke.uf2

patch:
	patch circuitpython/shared/netutils/dhcpserver.c <<< $$patch_dhcpserver_file

pythonvenv:
	python3 -m venv .

gitgetlatest:
	cd circuitpython && ./tools/git-checkout-latest-tag.sh

upgradepip:
	${RUNPYENV} cd circuitpython && pip3 install --upgrade pip

installreq:
	${RUNPYENV} cd circuitpython && pip3 install --upgrade -r requirements-dev.txt
	
installdoc:
	${RUNPYENV} cd circuitpython && pip3 install --upgrade -r requirements-doc.txt

installcircup:
	${RUNPYENV} cd circuitpython && pip3 install circup

fetchsubmod:
	${EXPORT} && cd circuitpython && make fetch-all-submodules

mpycross:
	${EXPORT} && cd circuitpython && make -C mpy-cross

fetchportsubmod:
	${EXPORT} && cd circuitpython/ports/raspberrypi && make fetch-port-submodules
	
compile:
	${RUNPYENV} ${EXPORT} && cd circuitpython/ports/raspberrypi && make -j$(nproc) BOARD=raspberry_pi_pico_w TRANSLATION=sv

resetflash:
	cp flash_nuke.uf2 ${MOUNTPRPI} 

copyfirmware:
	cp circuitpython/ports/raspberrypi/build-raspberry_pi_pico_w/firmware.uf2 ${MOUNTPRPI}

installpythondep:
	${RUNPYENV} circup install asyncio adafruit-circuitpython-httpserver adafruit_hid adafruit_debouncer adafruit_wsgi adafruit_hid.keyboard_layout_se
