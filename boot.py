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
