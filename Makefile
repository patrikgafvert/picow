TOOLCHAINNAME=arm-gnu-toolchain
TOOLCHAINVER=14.3.rel1
TOOLCHAINARCH=x86_64-arm-none-eabi
TOOLCHAINEXT=tar.xz
TOOLCHAINFILE=$(TOOLCHAINNAME)-$(TOOLCHAINVER)-$(TOOLCHAINARCH).$(TOOLCHAINEXT)
TOOLCHAINURL=https://developer.arm.com/-/media/Files/downloads/gnu/$(TOOLCHAINVER)/binrel/$(TOOLCHAINFILE)
TOOLCHAINDIRNAME=$(TOOLCHAINNAME)-$(TOOLCHAINVER)-$(TOOLCHAINARCH)
HOST=portal.local
IP=192.168.1.4

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
	openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=$(HOST)" -addext "subjectAltName=DNS:$(HOST)"

distclean:
	rm -rf $(TOOLCHAINDIRNAME) circuitpython pico-ducky cert.pem key.pem flash_nuke.uf2
