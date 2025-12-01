import storage; storage.getmount("/")
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
