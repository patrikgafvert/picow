define boot_py_file
import board
import digitalio

btn = digitalio.DigitalInOut(board.GP22)
btn.switch_to_input(pull=digitalio.Pull.UP)

if not btn.value:
    import storage
    storage.enable_usb_drive()
else:
    import usb_hid
    usb_hid.enable((usb_hid.Device.KEYBOARD,usb_hid.Device.CONSUMER_CONTROL))
endef

define code_py_file
import asyncio
import board
import digitalio
import usb_hid

from adafruit_debouncer import Debouncer
from adafruit_hid.keyboard import Keyboard
from keyboard_layout_win_sw import KeyboardLayout
keyboard = Keyboard(usb_hid.devices)
layout = KeyboardLayout(keyboard)

with open("password.txt", "r") as fd:
    password = fd.read().strip()

pin = digitalio.DigitalInOut(board.GP22)
pin.switch_to_input(pull=digitalio.Pull.UP)
button = Debouncer(pin)

(lambda l: (setattr(l, "direction", digitalio.Direction.OUTPUT), setattr(l, "value", True), l)[-1])(digitalio.DigitalInOut(board.LED))

async def send_keystrokes():
    layout.write(password)

async def button_task():
    while True:
        button.update()
        if button.fell:
        	await send_keystrokes()
        await asyncio.sleep(0.005)

async def main():
    await button_task()

asyncio.run(main())
endef

define patch_filesystem
@@ -176,7 +176,7 @@
         make_empty_file(&circuitpy->fatfs, "/settings.toml");
         #endif
         // make a sample code.py file
-        MAKE_FILE_WITH_OPTIONAL_CONTENTS(&circuitpy->fatfs, "/code.py", "print(\"Hello World!\")\n");
+        MAKE_FILE_WITH_OPTIONAL_CONTENTS(&circuitpy->fatfs, "/boot.py", "import storage\nstorage.enable_usb_drive()\n");

         // create empty lib directory
         res = f_mkdir(&circuitpy->fatfs, "/lib");
endef

define usb_own_pid_vid
supervisor.set_usb_identification(
manufacturer=“Project Pi”,
product=“Pico Gamepad 3”,
vid=0x239A,
pid=0x00F2
)
endef

define raspberry_pi_pico_patch
@@ -1,7 +1,13 @@
-USB_VID = 0x239A
-USB_PID = 0x80F4
-USB_PRODUCT = "Pico"
-USB_MANUFACTURER = "Raspberry Pi"
+USB_VID = $(MAKE_USB_VID)
+USB_PID = $(MAKE_USB_PID)
+USB_PRODUCT = $(MAKE_USB_PRODUCT)
+USB_MANUFACTURER = $(MAKE_USB_MANUFACTURER)
+
+CIRCUITPY_USB_MSC_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_CDC_DATA_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_CDC_CONSOLE_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_HID_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_MIDI_ENABLED_DEFAULT = 0

 CHIP_VARIANT = RP2040
 CHIP_FAMILY = rp2
endef

define raspberry_pi_pico_w_patch
@@ -1,7 +1,13 @@
-USB_VID = 0x239A
-USB_PID = 0x8120
-USB_PRODUCT = "Pico W"
-USB_MANUFACTURER = "Raspberry Pi"
+USB_VID = $(MAKE_USB_VID)
+USB_PID = $(MAKE_USB_PID)
+USB_PRODUCT = $(MAKE_USB_PRODUCT)
+USB_MANUFACTURER = $(MAKE_USB_MANUFACTURER)
+
+CIRCUITPY_USB_MSC_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_CDC_DATA_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_CDC_CONSOLE_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_HID_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_MIDI_ENABLED_DEFAULT = 0

 CHIP_VARIANT = RP2040
 CHIP_FAMILY = rp2
endef

define raspberry_pi_pico2_patch
@@ -1,7 +1,13 @@
-USB_VID = 0x2E8A
-USB_PID = 0x000B
-USB_PRODUCT = "Pico 2"
-USB_MANUFACTURER = "Raspberry Pi"
+USB_VID = $(MAKE_USB_VID)
+USB_PID = $(MAKE_USB_PID)
+USB_PRODUCT = $(MAKE_USB_PRODUCT)
+USB_MANUFACTURER = $(MAKE_USB_MANUFACTURER)
+
+CIRCUITPY_USB_MSC_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_CDC_DATA_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_CDC_CONSOLE_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_HID_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_MIDI_ENABLED_DEFAULT = 0

 CHIP_VARIANT = RP2350
 CHIP_PACKAGE = A
endef

define raspberry_pi_pico2_w_patch
@@ -1,7 +1,13 @@
-USB_VID = 0x239A
-USB_PID = 0x8162
-USB_PRODUCT = "Pico 2 W"
-USB_MANUFACTURER = "Raspberry Pi"
+USB_VID = $(MAKE_USB_VID)
+USB_PID = $(MAKE_USB_PID)
+USB_PRODUCT = $(MAKE_USB_PRODUCT)
+USB_MANUFACTURER = $(MAKE_USB_MANUFACTURER)
+
+CIRCUITPY_USB_MSC_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_CDC_DATA_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_CDC_CONSOLE_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_HID_ENABLED_DEFAULT = 0
+CIRCUITPY_USB_MIDI_ENABLED_DEFAULT = 0

 CHIP_VARIANT = RP2350
 CHIP_PACKAGE = A
endef

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
+    opt_write_n(&opt, DHCP_OPT_CAPTIVE_PORTAL,  $(shell echo -n $${#PORTALURL}), "$(PORTALURL)");
+    opt_write_n(&opt, DHCP_OPT_CAPTIVE_PORTAL1, $(shell echo -n $${#PORTALURL}), "$(PORTALURL)");
+    opt_write_n(&opt, DHCP_OPT_DOMAIN_NAME, 5, "local");
+    opt_write_n(&opt, DHCP_OPT_HOST_NAME,   6, "client");
     *opt++ = DHCP_OPT_END;
     struct netif *netif = ip_current_input_netif();
     dhcp_socket_sendto(&d->udp, netif, &dhcp_msg, opt - (uint8_t *)&dhcp_msg, 0xffffffff, PORT_DHCP_CLIENT);
endef

define no_dirty_patch
@@ -14,7 +14,6 @@ def get_version_info_from_git(repo_path, extra_args=[]):
                 [
                     "git",
                     "describe",
-                    "--dirty",
                     "--tags",
                     "--always",
                     "--first-parent",
endef

.SILENT:
SHELL := $(shell which bash)
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
MAKEOPT = -j$(shell nproc)
TOOLCHAINNAME = arm-gnu-toolchain
TOOLCHAINVER := $(shell curl -s "https://developer.arm.com/downloads/-/$(TOOLCHAINNAME)-downloads" | awk 'BEGIN{RS="</title>"}/<title>/{gsub(/.*<title>/,""); if(NR==2) print $$4}' | tr '[:upper:]' '[:lower:]')
TOOLCHAINARCH = x86_64-arm-none-eabi
TOOLCHAINEXT = tar.xz
TOOLCHAINFILE = $(TOOLCHAINNAME)-$(TOOLCHAINVER)-$(TOOLCHAINARCH).$(TOOLCHAINEXT)
TOOLCHAINURL = https://developer.arm.com/-/media/Files/downloads/gnu/$(TOOLCHAINVER)/binrel/$(TOOLCHAINFILE)
TOOLCHAINDIRNAME = $(TOOLCHAINNAME)-$(TOOLCHAINVER)-$(TOOLCHAINARCH)
HOST = portal
DOMAIN = local
FQDN = $(HOST).$(DOMAIN)
IP = 192.168.1.4
PORTALURL = https://$(FQDN)/
VENVDIR = venv/
RUNPYENV = source $(ROOT_DIR)$(VENVDIR)bin/activate 
EXPORT = export PATH=$(shell pwd)/$(TOOLCHAINDIRNAME)/bin:$$PATH
MAKE_USB_VID = 0x03F0
MAKE_USB_PID = 0x354A
MAKE_USB_PRODUCT = "Slim Keyboard"
MAKE_USB_MANUFACTURER = "HP, Inc"
MOUNTPCIR = mount | cut -f3 -d ' ' | sed -n '/CIRCUITPY/p'
MOUNTPRPI = mount | cut -f3 -d ' ' | sed -n '/RPI-RP2/p'

export

all:	download_$(TOOLCHAINDIRNAME) download_circuitpython chooseboard download_circuitpythonkeybl download_flash_nuke.uf2 gitgetlatest patch_raspberry_pi_pico patch_no_dirty patch_filesystem_file pythonvenv upgradepip installreq installdoc installcircup fetchportsubmod mpycross compile makecircuitpyhtonkeybl makekeympy resetflash copyfirmware installpythondep installfiles

chooseboard:
	while true; do \
	    i=1; \
	    declare -A boards; \
	    for b in $$(basename -a $$(ls -1d circuitpython/ports/raspberrypi/boards/raspberry_pi* 2>/dev/null | sort -t_ -k1,3 -k4)); do \
	        boards[$$i]=$$b; \
	        i=$$((i+1)); \
	    done; \
	    if [ $$i -eq 1 ]; then \
	        echo "Ingen board hittad i boards/!" >&2; exit 1; \
	    fi; \
	    echo "Välj board:" >&2; \
	    for n in $$(printf "%s\n" "$${!boards[@]}" | sort -n); do \
	        echo "$$n) $${boards[$$n]}" >&2; \
	    done; \
	    echo -n "Ange nummer [1-$$((i-1))]: " >&2; \
	    read val; \
	    if [[ -n $${boards[$$val]} ]]; then \
	        echo -n $${boards[$$val]} > BOARD; \
	        break; \
	    else \
	        echo "Ogiltigt val! Försök igen." >&2; \
	    fi; \
	done

download_$(TOOLCHAINDIRNAME):
	curl -L -# $(TOOLCHAINURL) | tar --xz -xf -

download_circuitpython:
	git clone https://github.com/adafruit/circuitpython

download_circuitpythonkeybl:
	git clone https://github.com/Neradoc/Circuitpython_Keyboard_Layouts

download_flash_nuke.uf2:
	curl -LO https://datasheets.raspberrypi.com/soft/flash_nuke.uf2

gitgetlatest:
	cd circuitpython && ./tools/git-checkout-latest-tag.sh

patch_raspberry_pi_pico:
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico/mpconfigboard.mk <<< $${raspberry_pi_pico_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico_w/mpconfigboard.mk <<< $${raspberry_pi_pico_w_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico2/mpconfigboard.mk <<< $${raspberry_pi_pico2_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico2_w/mpconfigboard.mk <<< $${raspberry_pi_pico2_w_patch}

patch_dhcpserver_file:
	patch $(ROOT_DIR)circuitpython/shared/netutils/dhcpserver.c <<< $${patch_dhcpserver_file}

patch_no_dirty:
	patch $(ROOT_DIR)circuitpython/py/version.py <<< $${no_dirty_patch}

patch_filesystem_file:
	patch $(ROOT_DIR)circuitpython/supervisor/shared/filesystem.c <<< $${patch_filesystem}

pythonvenv:
	python3 -m venv $(VENVDIR)

upgradepip:
	$(RUNPYENV) && cd circuitpython && pip3 install --upgrade pip

installreq:
	$(RUNPYENV) && cd circuitpython && pip3 install --upgrade -r requirements-dev.txt
	
installdoc:
	$(RUNPYENV) && cd circuitpython && pip3 install --upgrade -r requirements-doc.txt

installcircup:
	$(RUNPYENV) && cd circuitpython && pip3 install circup

fetchsubmod:
	$(EXPORT) && cd circuitpython && $(MAKE) $(MAKEOPT) fetch-all-submodules

fetchportsubmod:
	$(EXPORT) && cd circuitpython/ports/raspberrypi && $(MAKE) $(MAKEOPT) fetch-port-submodules
	
mpycross:
	cd circuitpython && $(MAKE) $(MAKEOPT) -C mpy-cross

compile:
	$(RUNPYENV) && $(EXPORT) && cd circuitpython/ports/raspberrypi && $(MAKE) $(MAKEOPT) BOARD=$$(cat $(ROOT_DIR)BOARD) TRANSLATION=sv

makecircuitpyhtonkeybl:
	$(RUNPYENV) && pip3 install -r Circuitpython_Keyboard_Layouts/requirements-dev.txt
	$(RUNPYENV) && PYTHONPATH="Circuitpython_Keyboard_Layouts" python3 -m generator -k "https://kbdlayout.info/kbdsw" -l "sw" --output-layout keyboard_layout_win_sw.py --output-keycode keycode_win_sw.py

makekeympy:
	cd $(ROOT_DIR) && $(ROOT_DIR)circuitpython/mpy-cross/build/mpy-cross keyboard_layout_win_sw.py
	cd $(ROOT_DIR) && $(ROOT_DIR)circuitpython/mpy-cross/build/mpy-cross keycode_win_sw.py

resetflash:
	echo "Insert the pico with the reset key pressed to install and reset the firmware"
	echo "Press ENTER to continue"	
	read
	while [ -z "$$($(MOUNTPRPI))" ] || [ ! -d "$$($(MOUNTPRPI))" ]; do sleep 1; done
	cp -v $(ROOT_DIR)flash_nuke.uf2 $$($(MOUNTPRPI))
	echo "Waiting 10sec to the device to come back"
	sleep 10

copyfirmware:
	while [ -z "$$($(MOUNTPRPI))" ] || [ ! -d "$$($(MOUNTPRPI))" ]; do sleep 1; done
	cp -v $(ROOT_DIR)circuitpython/ports/raspberrypi/build-$$(cat $(ROOT_DIR)BOARD)/firmware.uf2 $$($(MOUNTPRPI))

installpythondep:
	while [ -z "$$($(MOUNTPCIR))" ] || [ ! -d "$$($(MOUNTPCIR))" ]; do sleep 1; done
	$(RUNPYENV) && circup install asyncio adafruit_hid adafruit_debouncer

installfiles:
	while [ -z "$$($(MOUNTPCIR))" ] || [ ! -d "$$($(MOUNTPCIR))" ]; do sleep 1; done
	cp -v keyboard_layout_win_sw.py keycode_win_sw.py $$($(MOUNTPCIR))/lib
	printf '%s\n' "$$boot_py_file" > $$($(MOUNTPCIR))/boot.py
	printf '%s\n' "$$code_py_file" > $$($(MOUNTPCIR))/code.py
	printf '%s' "Password123!" > $$($(MOUNTPCIR))/password.txt
