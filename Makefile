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
import board
import digitalio
import usb_hid
import time

from adafruit_debouncer import Debouncer
from adafruit_hid.keyboard import Keyboard
from adafruit_hid.keycode import Keycode
from keyboard_layout_win_sw import KeyboardLayout

keyboard = Keyboard(usb_hid.devices)
layout = KeyboardLayout(keyboard)

def load_text(filename):
    try:
        with open(filename, "r") as fd:
            return fd.read().strip()
    except OSError:
        return ""

button_text   = load_text("button.txt")
caps_text     = load_text("caps_lock.txt")
num_text      = load_text("num_lock.txt")
scroll_text   = load_text("scroll_lock.txt")

pin = digitalio.DigitalInOut(board.GP22)
pin.switch_to_input(pull=digitalio.Pull.UP)
button = Debouncer(pin)

def check_button():
    button.update()
    if button.fell and button_text:
        layout.write(button_text)

def handle_lock(led, keycode, text):
    if keyboard.led_on(led) and text:
        time.sleep(0.5)
        keyboard.send(keycode)
        layout.write(text)

def main():
    while True:
        check_button()
        handle_lock(Keyboard.LED_CAPS_LOCK,   Keycode.CAPS_LOCK,      caps_text)
        handle_lock(Keyboard.LED_NUM_LOCK,    Keycode.KEYPAD_NUMLOCK, num_text)
        handle_lock(Keyboard.LED_SCROLL_LOCK, Keycode.SCROLL_LOCK,    scroll_text)
        time.sleep(0.01)

main()
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

define waveshare_rp2040_one_patch
@@ -1,7 +1,13 @@
-USB_VID = 0x2E8A
-USB_PID = 0x103A
-USB_PRODUCT = "RP2040-One"
-USB_MANUFACTURER = "Waveshare Electronics"
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

define waveshare_rp2350_one_patch
@@ -1,7 +1,13 @@
-USB_VID = 0x2E8A
-USB_PID = 0x10B5
-USB_PRODUCT = "RP2350-One"
-USB_MANUFACTURER = "Waveshare Electronics"
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
 CHIP_FAMILY = rp2
endef

define pico_h_patch
@@ -14,2 +14,3 @@
 #define CIRCUITPY_BOARD_I2C         (1)
 #define CIRCUITPY_BOARD_I2C_PIN     {{.scl = &pin_GPIO5, .sda = &pin_GPIO4}}
+#define CIRCUITPY_DRIVE_LABEL "$(DRIVE_LABEL)"
endef

define waveshare_h_patch
@@ -20,3 +20,4 @@
 #define DEFAULT_SPI_BUS_MISO (&pin_GPIO8)
 
 #define MICROPY_HW_NEOPIXEL (&pin_GPIO16)
+#define CIRCUITPY_DRIVE_LABEL "$(DRIVE_LABEL)"
endef

define no_dirty_patch
@@ -14,7 +14,6 @@
                 [
                     "git",
                     "describe",
-                    "--dirty",
                     "--tags",
                     "--always",
                     "--first-parent",
endef

define no_usb_serial_patch
@@ -78,7 +78,7 @@ static const uint8_t device_descriptor_template[] = {
 #define DEVICE_MANUFACTURER_STRING_INDEX (14)
     0xFF,        // 15 iProduct (String Index) [SET AT RUNTIME]
 #define DEVICE_PRODUCT_STRING_INDEX (15)
-    0xFF,        // 16 iSerialNumber (String Index)  [SET AT RUNTIME]
+    0x00,        // 16 iSerialNumber (String Index) - disabled
 #define DEVICE_SERIAL_NUMBER_STRING_INDEX (16)
     0x01,        // 17 bNumConfigurations 1
 };
@@ -119,10 +119,6 @@ static bool usb_build_device_descriptor(const usb_identification_t *identificati
     device_descriptor[DEVICE_PRODUCT_STRING_INDEX] = current_interface_string;
     current_interface_string++;
 
-    usb_add_interface_string(current_interface_string, serial_number_hex_string);
-    device_descriptor[DEVICE_SERIAL_NUMBER_STRING_INDEX] = current_interface_string;
-    current_interface_string++;
-
     return true;
 }
 
endef

# Fix a GCC false positive in the vendored mbedtls GCM code
define mbedtls_array_bounds_patch
@@ -728,7 +728,8 @@
 # are compiled out.
 $$(patsubst %.c,$$(BUILD)/%.o,$$(SRC_MBEDTLS)) $$(OBJ_MBEDTLS): CFLAGS += \$(EMPTY)
 	-Wno-suggest-attribute=format \$(EMPTY)
-	-Wno-unused-but-set-variable
+	-Wno-unused-but-set-variable \$(EMPTY)
+	-Wno-array-bounds
 else
 OBJ_MBEDTLS :=
 endif
endef

#.SILENT:
EMPTY :=
SHELL := $(shell which bash)
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
MAKEOPT = -j$(shell nproc)
TOOLCHAINNAME = arm-gnu-toolchain
TOOLCHAINPKG = gnu-toolchain
TOOLCHAINVER := $(shell curl -s "https://gitlab.arm.com/api/v4/projects/tooling%2Fgnu-toolchains-for-arm/repository/branches?per_page=100" | awk 'BEGIN{RS="\""} /^releases\//{sub("releases/",""); print}' | sort -V | tail -1)
TOOLCHAINARCH = x86_64-arm-none-eabi
TOOLCHAINEXT = tar.xz
TOOLCHAINFILE = $(TOOLCHAINNAME)-$(TOOLCHAINVER)-$(TOOLCHAINARCH).$(TOOLCHAINEXT)
TOOLCHAINURL = https://gitlab.arm.com/api/v4/projects/tooling%2Fgnu-toolchains-for-arm/packages/generic/$(TOOLCHAINPKG)/$(TOOLCHAINVER)/$(TOOLCHAINFILE)
TOOLCHAINDIRNAME = $(TOOLCHAINNAME)-$(TOOLCHAINVER)-$(TOOLCHAINARCH)
VENVDIR = venv/
RUNPYENV = source $(ROOT_DIR)$(VENVDIR)bin/activate
EXPORT = export PATH=$(shell pwd)/$(TOOLCHAINDIRNAME)/bin:$$PATH
MAKE_USB_VID = 0x03F0
MAKE_USB_PID = 0x354A
MAKE_USB_PRODUCT = "Slim Keyboard"
MAKE_USB_MANUFACTURER = "HP, Inc"
DRIVE_LABEL = MASTERKEY
MOUNTPCIR = mount | cut -f3 -d ' ' | sed -n '/$(DRIVE_LABEL)/p'
MOUNTPICO1 = mount | cut -f3 -d ' ' | sed -n '/RPI-RP2/p'
MOUNTPICO2 = mount | cut -f3 -d ' ' | sed -n '/RP2350/p'
BOARD_FILE := $(ROOT_DIR)BOARD
BOARD_NAME := $(shell cat $(BOARD_FILE) 2>/dev/null)
STAMP_DIR = .stamps

# Välj mount-avkänning utifrån vald board; Pico 2 (RP2350) monteras som "RP2350"
ifneq ($(findstring 2,$(BOARD_NAME)),)
MOUNTPICO := $(MOUNTPICO2)
else
MOUNTPICO := $(MOUNTPICO1)
endif

export boot_py_file code_py_file \
       patch_filesystem raspberry_pi_pico_patch raspberry_pi_pico_w_patch \
       raspberry_pi_pico2_patch raspberry_pi_pico2_w_patch \
       waveshare_rp2040_one_patch waveshare_rp2350_one_patch \
       pico_h_patch waveshare_h_patch no_dirty_patch no_usb_serial_patch \
       mbedtls_array_bounds_patch

# ===================================================================
# Huvudmål
# ===================================================================

.PHONY: all chooseboard flash resetflash copyfirmware installpythondep \
        installfiles distclean clean fetchsubmod visa_block

all: flash

$(STAMP_DIR):
	mkdir -p $(STAMP_DIR)

$(STAMP_DIR)/toolchain: | $(STAMP_DIR)
	curl -L -# $(TOOLCHAINURL) | tar --xz -xf -
	@touch $@

$(STAMP_DIR)/circuitpython: | $(STAMP_DIR)
	git clone https://github.com/adafruit/circuitpython
	@touch $@

$(STAMP_DIR)/circuitpython-latest: $(STAMP_DIR)/circuitpython
	cd circuitpython && ./tools/git-checkout-latest-tag.sh
	@touch $@

$(STAMP_DIR)/keyboard-layouts: | $(STAMP_DIR)
	git clone https://github.com/Neradoc/Circuitpython_Keyboard_Layouts
	@touch $@

$(STAMP_DIR)/flash-nuke: | $(STAMP_DIR)
	curl -LO https://datasheets.raspberrypi.com/soft/flash_nuke.uf2
	@touch $@

$(STAMP_DIR)/venv: | $(STAMP_DIR)
	python3 -m venv $(VENVDIR)
	@touch $@

$(STAMP_DIR)/pip: $(STAMP_DIR)/venv
	$(RUNPYENV) && cd circuitpython && pip3 install --upgrade pip
	@touch $@

$(STAMP_DIR)/requirements-dev: $(STAMP_DIR)/pip
	$(RUNPYENV) && cd circuitpython && pip3 install --upgrade -r requirements-dev.txt
	@touch $@

$(STAMP_DIR)/requirements-doc: $(STAMP_DIR)/pip
	$(RUNPYENV) && cd circuitpython && pip3 install --upgrade -r requirements-doc.txt
	@touch $@

$(STAMP_DIR)/circup: $(STAMP_DIR)/pip
	$(RUNPYENV) && cd circuitpython && pip3 install circup
	@touch $@

$(STAMP_DIR)/submodules: $(STAMP_DIR)/circuitpython-latest
	$(EXPORT) && cd circuitpython && $(MAKE) $(MAKEOPT) fetch-all-submodules
	$(EXPORT) && cd circuitpython/ports/raspberrypi && $(MAKE) $(MAKEOPT) fetch-port-submodules
	@touch $@

$(STAMP_DIR)/patch-pico: $(STAMP_DIR)/circuitpython-latest
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico/mpconfigboard.mk <<< $${raspberry_pi_pico_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico_w/mpconfigboard.mk <<< $${raspberry_pi_pico_w_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico2/mpconfigboard.mk <<< $${raspberry_pi_pico2_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico2_w/mpconfigboard.mk <<< $${raspberry_pi_pico2_w_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/waveshare_rp2040_one/mpconfigboard.mk <<< $${waveshare_rp2040_one_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/waveshare_rp2350_one/mpconfigboard.mk <<< $${waveshare_rp2350_one_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico/mpconfigboard.h <<< $${pico_h_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico_w/mpconfigboard.h <<< $${pico_h_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico2/mpconfigboard.h <<< $${pico_h_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/raspberry_pi_pico2_w/mpconfigboard.h <<< $${pico_h_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/waveshare_rp2040_one/mpconfigboard.h <<< $${waveshare_h_patch}
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/boards/waveshare_rp2350_one/mpconfigboard.h <<< $${waveshare_h_patch}
	@touch $@

$(STAMP_DIR)/patch-no-dirty: $(STAMP_DIR)/circuitpython-latest
	patch $(ROOT_DIR)circuitpython/py/version.py <<< $${no_dirty_patch}
	@touch $@

$(STAMP_DIR)/patch-no-usb-serial: $(STAMP_DIR)/circuitpython-latest
	patch $(ROOT_DIR)circuitpython/supervisor/shared/usb/usb_desc.c <<< $${no_usb_serial_patch}
	@touch $@

$(STAMP_DIR)/patch-filesystem: $(STAMP_DIR)/circuitpython-latest
	patch $(ROOT_DIR)circuitpython/supervisor/shared/filesystem.c <<< $${patch_filesystem}
	@touch $@

$(STAMP_DIR)/patch-mbedtls: $(STAMP_DIR)/circuitpython-latest
	patch $(ROOT_DIR)circuitpython/ports/raspberrypi/Makefile <<< $${mbedtls_array_bounds_patch}
	@touch $@

$(STAMP_DIR)/mpy-cross: $(STAMP_DIR)/toolchain $(STAMP_DIR)/circuitpython-latest
	cd circuitpython && $(MAKE) $(MAKEOPT) -C mpy-cross
	@touch $@

$(STAMP_DIR)/keyboard-layouts-req: $(STAMP_DIR)/keyboard-layouts $(STAMP_DIR)/pip
	$(RUNPYENV) && pip3 install -r Circuitpython_Keyboard_Layouts/requirements-dev.txt
	@touch $@

keyboard_layout_win_sw.py keycode_win_sw.py &: $(STAMP_DIR)/keyboard-layouts-req
	$(RUNPYENV) && PYTHONPATH="Circuitpython_Keyboard_Layouts" python3 -m generator -k "https://kbdlayout.info/kbdsw" -l "sw" --output-layout keyboard_layout_win_sw.py --output-keycode keycode_win_sw.py

keyboard_layout_win_sw.mpy keycode_win_sw.mpy &: keyboard_layout_win_sw.py keycode_win_sw.py $(STAMP_DIR)/mpy-cross
	cd $(ROOT_DIR) && $(ROOT_DIR)circuitpython/mpy-cross/build/mpy-cross keyboard_layout_win_sw.py
	cd $(ROOT_DIR) && $(ROOT_DIR)circuitpython/mpy-cross/build/mpy-cross keycode_win_sw.py

$(STAMP_DIR)/compile: $(STAMP_DIR)/patch-pico $(STAMP_DIR)/patch-filesystem $(STAMP_DIR)/patch-mbedtls $(STAMP_DIR)/patch-no-usb-serial $(STAMP_DIR)/patch-no-dirty $(STAMP_DIR)/submodules $(STAMP_DIR)/mpy-cross $(STAMP_DIR)/requirements-dev $(STAMP_DIR)/requirements-doc
	@test -f $(BOARD_FILE) || $(MAKE) chooseboard
	$(RUNPYENV) && $(EXPORT) && cd circuitpython/ports/raspberrypi && $(MAKE) $(MAKEOPT) BOARD=$$(cat $(ROOT_DIR)BOARD) TRANSLATION=sv
	@touch $@

chooseboard:
	while true; do \
	    i=1; \
	    declare -A boards; \
	    for b in $$(basename -a $$(ls -1d circuitpython/ports/raspberrypi/boards/raspberry_pi* 2>/dev/null; ls -1d circuitpython/ports/raspberrypi/boards/waveshare*one 2>/dev/null | sort -t_ -k1,3 -k4)); do \
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

resetflash:
	echo "Insert the pico with the reset key pressed to install and reset the firmware"
	echo "Press ENTER to continue"
	read
	while [ -z "$$($(MOUNTPICO))" ] || [ ! -d "$$($(MOUNTPICO))" ]; do sleep 1; done
	cp -v $(ROOT_DIR)flash_nuke.uf2 $$($(MOUNTPICO))
	for ((i=15; i>=1; i--)); do echo -ne "\rWaiting $$i sec to the device to come back"; sleep 1; done; echo

copyfirmware: $(STAMP_DIR)/compile
	while [ -z "$$($(MOUNTPICO))" ] || [ ! -d "$$($(MOUNTPICO))" ]; do sleep 1; done
	cp -v $(ROOT_DIR)circuitpython/ports/raspberrypi/build-$$(cat $(ROOT_DIR)BOARD)/firmware.uf2 $$($(MOUNTPICO))

installpythondep: $(STAMP_DIR)/circup
	while [ -z "$$($(MOUNTPCIR))" ] || [ ! -d "$$($(MOUNTPCIR))" ]; do sleep 1; done
	$(RUNPYENV) && circup --path $$($(MOUNTPCIR)) install asyncio adafruit_hid adafruit_debouncer

installfiles: keyboard_layout_win_sw.mpy keycode_win_sw.mpy
	while [ -z "$$($(MOUNTPCIR))" ] || [ ! -d "$$($(MOUNTPCIR))" ]; do sleep 1; done
	cp -v keyboard_layout_win_sw.mpy keycode_win_sw.mpy $$($(MOUNTPCIR))/lib
	printf '%s\n' "$$boot_py_file" > $$($(MOUNTPCIR))/boot.py
	printf '%s\n' "$$code_py_file" > $$($(MOUNTPCIR))/code.py
	printf '%s' "Caps_Lock_Text" > $$($(MOUNTPCIR))/caps_lock.txt
	printf '%s' "Num_Lock_Text" > $$($(MOUNTPCIR))/num_lock.txt
	printf '%s' "Scroll_Lock_Text" > $$($(MOUNTPCIR))/scroll_lock.txt
	printf '%s' "Button_Text" > $$($(MOUNTPCIR))/button.txt

flash: $(STAMP_DIR)/compile keyboard_layout_win_sw.mpy keycode_win_sw.mpy $(STAMP_DIR)/circup $(STAMP_DIR)/flash-nuke
	$(MAKE) resetflash
	$(MAKE) copyfirmware
	$(MAKE) installpythondep
	$(MAKE) installfiles

fetchsubmod:
	$(EXPORT) && cd circuitpython && $(MAKE) $(MAKEOPT) fetch-all-submodules

clean:
	@test -f $(BOARD_FILE) || { echo "Ingen board vald. Kör först: make chooseboard"; exit 1; }
	$(EXPORT) && cd circuitpython/ports/raspberrypi && $(MAKE) BOARD=$(BOARD_NAME) clean
	@rm -f $(STAMP_DIR)/compile $(BOARD_FILE)
	@echo "Byggkatalog och compile-stamp rensade, BOARD-fil borttagen"

distclean:
	git clean -ffdx

visa_block:
	@$(info $(value $(word 2,$(MAKECMDGOALS))))

%:
	@:
