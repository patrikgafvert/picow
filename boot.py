import storage
import usb_hid
import usb_cdc
import usb_midi

#storage.disable_usb_drive()
usb_midi.disable()
usb_cdc.disable()
usb_hid.enable((usb_hid.Device.KEYBOARD,))
