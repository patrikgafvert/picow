#!/bin/bash
# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
# https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/
# https://github.com/adafruit/circuitpython.git
# https://github.com/dbisu/pico-ducky.git

NAME=arm-gnu-toolchain
VER=14.3.rel1
ARCH=x86_64-arm-none-eabi
EXT=tar.xz
FILE=${NAME}-${VER}-${ARCH}.${EXT}
URL=https://developer.arm.com/-/media/Files/downloads/gnu/${VER}/binrel/${FILE}
NAME=${NAME}-${VER}-${ARCH}
[[ ! -d $NAME ]] && curl -# -L ${URL} | tar --xz -xf -
export PATH=$(pwd)/$NAME/bin:$PATH
# which arm-none-eabi-gcc
git clone https://github.com/adafruit/circuitpython.git
cd circuitpython
python3 -m venv .
. ./bin/activate
pip3 install --upgrade pip
pip3 install --upgrade -r requirements-dev.txt
pip3 install --upgrade -r requirements-doc.txt
git checkout main
make fetch-all-submodules
pre-commit install
make -C mpy-cross
cd ports/raspberrypi
make fetch-port-submodules
cat << "EOF" > dhcpserver.c.patch
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
+    opt_write_n(&opt, DHCP_OPT_CAPTIVE_PORTAL,  26, "https://portal.local/login");
+    opt_write_n(&opt, DHCP_OPT_CAPTIVE_PORTAL1, 26, "https://portal.local/login");
+    opt_write_n(&opt, DHCP_OPT_HOST_NAME,   6, "client");
+    opt_write_n(&opt, DHCP_OPT_DOMAIN_NAME, 5, "local");
     *opt++ = DHCP_OPT_END;
     struct netif *netif = ip_current_input_netif();
     dhcp_socket_sendto(&d->udp, netif, &dhcp_msg, opt - (uint8_t *)&dhcp_msg, 0xffffffff, PORT_DHCP_CLIENT);
EOF
patch ../../shared/netutils/dhcpserver.c < dhcpserver.c.patch 
make -j$(nproc) BOARD=raspberry_pi_pico_w TRANSLATION=sv

# cp build-raspberry_pi_pico_w/firmware.uf2 /run/media/patrik/RPI-RP2/
# cp picow/circuitpython/ports/raspberrypi/build-raspberry_pi_pico_w /run/media/patrik/RPI-RP2/
deactivate

#cd ports/raspberrypi
#make clean BOARD=raspberry_pi_pico_w TRANSLATION=sv


#screen /dev/ttyACM0     (  to exit <CTRL><A> <\>  )

# import wifi
# wifi.radio.start_ap("Test", "12341234")

echo "cp circuitpython/ports/raspberrypi/build-raspberry_pi_pico_w/firmware.uf2 /run/media/patrik/RPI-RP2/"
