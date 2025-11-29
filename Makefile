define patch_codepy
@@ -12,30 +12,6 @@ import digitalio
 from board import *
 import board
 from duckyinpython import *
-if(board.board_id == 'raspberry_pi_pico_w' or board.board_id == 'raspberry_pi_pico2_w'):
-    import wifi
-    from webapp import *
-
-
-# sleep at the start to allow the device to be recognized by the host computer
-time.sleep(.5)
-
-def startWiFi():
-    import ipaddress
-    # Get wifi details and more from a secrets.py file
-    try:
-        from secrets import secrets
-    except ImportError:
-        print("WiFi secrets are kept in secrets.py, please add them there!")
-        raise
-
-    print("Connect wifi")
-    #wifi.radio.connect(secrets['ssid'],secrets['password'])
-    wifi.radio.start_ap(secrets['ssid'],secrets['password'])
-
-    HOST = repr(wifi.radio.ipv4_address_ap)
-    PORT = 80        # Port to listen on
-    print(HOST,PORT)

 # turn off automatically reloading when files are written to the pico
 #supervisor.disable_autoreload()
@@ -47,40 +23,18 @@ elif(board.board_id == 'raspberry_pi_pico_w' or board.board_id == 'raspberry_pi_
     led = digitalio.DigitalInOut(board.LED)
     led.switch_to_output()

-async def run_payload_on_startup():
-    progStatus = False
-    progStatus = getProgrammingStatus()
-    print("progStatus", progStatus)
-    if(progStatus == False):
-        print("Finding payload")
-        if "loot.bin" in os.listdir("/"):
-            print("loot.bin exists, skipping payload execution.")
-        else:
-            payload = selectPayload()
-            await asyncio.sleep(0.1)
-            print("Running")
-            await runScript(payload)
-    else:
-        print("Done")
-
-
 led_state = False

 async def main_loop():
     global led,button1

     button_task = asyncio.create_task(monitor_buttons(button1))
-    payload_task = asyncio.create_task(run_payload_on_startup())
     led_task = asyncio.create_task(monitor_led_changes())
     if(board.board_id == 'raspberry_pi_pico_w' or board.board_id == 'raspberry_pi_pico2_w'):
         pico_led_task = asyncio.create_task(blink_pico_w_led(led))
-        print("Starting Wifi")
-        startWiFi()
-        print("Starting Web Service")
-        webservice_task = asyncio.create_task(startWebService())
-        await asyncio.gather(pico_led_task, button_task, webservice_task, payload_task, led_task)
+        await asyncio.gather(pico_led_task, button_task, led_task)
     else:
         pico_led_task = asyncio.create_task(blink_pico_led(led))
-        await asyncio.gather(pico_led_task, button_task, payload_task, led_task )
+        await asyncio.gather(pico_led_task, button_task, led_task)

 asyncio.run(main_loop())
endef


define file_boot_py
import board
import digitalio
import storage
import usb_hid

btn = digitalio.DigitalInOut(board.GP22)
btn.switch_to_input(pull=digitalio.Pull.UP)

if not btn.value:
    storage.enable_usb_drive()
else:
    storage.disable_usb_drive()
    usb_hid.enable((usb_hid.Device.KEYBOARD,usb_hid.Device.CONSUMER_CONTROL))
endef

define patch_keysw
@@ -20,13 +20,13 @@
 from adafruit_hid.consumer_control_code import ConsumerControlCode

 # comment out these lines for non_US keyboards
-from adafruit_hid.keyboard_layout_us import KeyboardLayoutUS as KeyboardLayout
-from adafruit_hid.keycode import Keycode
+#from adafruit_hid.keyboard_layout_us import KeyboardLayoutUS as KeyboardLayout
+#from adafruit_hid.keycode import Keycode

 # uncomment these lines for non_US keyboards
 # replace LANG with appropriate language
-#from keyboard_layout_win_LANG import KeyboardLayout as KeyboardLayout
-#from keycode_win_LANG import Keycode
+from keyboard_layout_win_sw import KeyboardLayout as KeyboardLayout
+from keycode_win_sw import Keycode

 def _capsOn():
     return kbd.led_on(Keyboard.LED_CAPS_LOCK)
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
+CIRCUITPY_USB_MSC_ENABLED_DEFAULT = 1
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
+CIRCUITPY_USB_MSC_ENABLED_DEFAULT = 1
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
+CIRCUITPY_USB_MSC_ENABLED_DEFAULT = 1
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
+CIRCUITPY_USB_MSC_ENABLED_DEFAULT = 1
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
RUNPYENV = source $(ROOT_DIR)venv/bin/activate 
EXPORT = export PATH=$(shell pwd)/$(TOOLCHAINDIRNAME)/bin:$$PATH
MAKE_USB_VID = 0x03F0
MAKE_USB_PID = 0x354A
MAKE_USB_PRODUCT = "Slim Keyboard"
MAKE_USB_MANUFACTURER = "HP, Inc"
MOUNTPCIR = $(shell mount | cut -f3 -d ' ' | sed -n '/CIRCUITPY$$/p')
MOUNTPRPI = $(shell mount | cut -f3 -d ' ' | sed -n '/RPI-RP2$$/p')

export

.PHONY: list all chooseboard download circuitpython circuitpythonkeybl pico-ducky makecert distclean patch pythonvenv gitgetlatest upgradepip installreq installdoc installcircup fetchsubmod mpycross fetchportsubmod compile resetflash copyfirmware installpythondep makecircuitpyhtonkeybl makekeympy $(TOOLCHAINDIRNAME)

all: download makecert

list:
	grep -E '^[a-zA-Z0-9_-]+:.*$$' Makefile | cut -d':' -f1

download: $(TOOLCHAINDIRNAME) circuitpython circuitpythonkeybl pico-ducky flash_nuke.uf2

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

$(TOOLCHAINDIRNAME):
	curl -L -# $(TOOLCHAINURL) | tar --xz -xf -

circuitpython:
	git clone https://github.com/adafruit/circuitpython

circuitpythonkeybl:
	git clone https://github.com/Neradoc/Circuitpython_Keyboard_Layouts

pico-ducky:
	git clone https://github.com/dbisu/pico-ducky

flash_nuke.uf2:
	curl -LO https://datasheets.raspberrypi.com/soft/flash_nuke.uf2

gitgetlatest:
	cd circuitpython && ./tools/git-checkout-latest-tag.sh

patch_raspberry_pi_pico:
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico/mpconfigboard.mk <<< $${raspberry_pi_pico_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico_w/mpconfigboard.mk <<< $${raspberry_pi_pico_w_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico2/mpconfigboard.mk <<< $${raspberry_pi_pico2_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico2_w/mpconfigboard.mk <<< $${raspberry_pi_pico2_w_patch}

patch:
	patch $(ROOT_DIR)circuitpython/shared/netutils/dhcpserver.c <<< $${patch_dhcpserver_file}

patch_no_dirty:
	patch $(ROOT_DIR)circuitpython/py/version.py <<< $${no_dirty_patch}

makecert:
	openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=$(FQDN)" -addext "subjectAltName=DNS:$(FQDN)"

pythonvenv:
	python3 -m venv venv

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

mpycross:
	cd circuitpython && $(MAKE) $(MAKEOPT) -C mpy-cross

fetchportsubmod:
	$(EXPORT) && cd circuitpython/ports/raspberrypi && $(MAKE) $(MAKEOPT) fetch-port-submodules
	
compile:
	$(RUNPYENV) && $(EXPORT) && cd circuitpython/ports/raspberrypi && $(MAKE) $(MAKEOPT) BOARD=$$(cat $(ROOT_DIR)BOARD) TRANSLATION=sv

resetflash:
	cp $(ROOT_DIR)flash_nuke.uf2 $(MOUNTPRPI) 

copyfirmware:
	cp $(ROOT_DIR)circuitpython/ports/raspberrypi/build-$$(cat $(ROOT_DIR)BOARD)/firmware.uf2 $(MOUNTPRPI)

installpythondep:
	$(RUNPYENV) && circup install asyncio adafruit_hid adafruit_debouncer

makecircuitpyhtonkeybl:
	$(RUNPYENV) && pip3 install -r Circuitpython_Keyboard_Layouts/requirements-dev.txt
	$(RUNPYENV) && PYTHONPATH="Circuitpython_Keyboard_Layouts" python3 -m generator -k "https://kbdlayout.info/kbdsw" -l "sw" --output-layout $(ROOT_DIR)keyboard_layout_win_sw.py --output-keycode $(ROOT_DIR)keycode_win_sw.py

makekeympy:
	$(ROOT_DIR)circuitpython/mpy-cross/build/mpy-cross $(ROOT_DIR)keyboard_layout_win_sw.py
	$(ROOT_DIR)circuitpython/mpy-cross/build/mpy-cross $(ROOT_DIR)keycode_win_sw.py

makeduckympy:
	$(ROOT_DIR)circuitpython/mpy-cross/build/mpy-cross $(ROOT_DIR)pico-ducky/duckyinpython.py

filebootpy:
	printf '%s\n' "$$file_boot_py" > $(ROOT_DIR)boot.py

patchkeyb:
	patch $(ROOT_DIR)pico-ducky/duckyinpython.py <<< $${patch_keysw}
	
patchcodepy:
	patch $(ROOT_DIR)pico-ducky/code.py <<< $${patch_codepy}
	
print-defines:
	$(info $(raspberry_pi_pico2_patch))

distclean:
	rm -rf $(ROOT_DIR)$(TOOLCHAINDIRNAME) $(ROOT_DIR)circuitpython $(ROOT_DIR)pico-ducky $(ROOT_DIR)cert.pem $(ROOT_DIR)key.pem $(ROOT_DIR)flash_nuke.uf2 $(ROOT_DIR)BOARD $(ROOT_DIR)Circuitpython_Keyboard_Layouts $(ROOT_DIR)keyboard_layout_win_sw.py  $(ROOT_DIR)keycode_win_sw.py $(ROOT_DIR)keyboard_layout_win_sw.mpy $(ROOT_DIR)keycode_win_sw.mpy $(ROOT_DIR)venv
