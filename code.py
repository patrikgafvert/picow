"""
---------------------------------------------------------------
CircuitPython Captive Portal med HTTPS och DNS-hijack
---------------------------------------------------------------

Innan du kör detta skript behöver du generera certifikat och privat nyckel
för HTTPS (self-signed fungerar för test):

1. Öppna terminal/kommandoprompt på din dator.

2. Kör följande kommando för att skapa certifikat och nyckel:

   openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes

   openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes \
   -subj "/CN=192.168.4.1" -addext "subjectAltName=IP:192.168.4.1"
   
   DHCP Option 114
   https://192.168.4.1/captive.json

   openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes \
   -subj "/CN=portal.local" -addext "subjectAltName=DNS:portal.local"

   DHCP Option 114
   https://portal.local/captive.json

   - key.pem  : Privat nyckel
   - cert.pem : Certifikat (self-signed)
   - days=365 : Certifikatet gäller i 1 år
   - -nodes   : ingen lösenfras på nyckeln (obligatoriskt för CircuitPython)

3. Kopiera filerna cert.pem och key.pem till CIRCUITPY-rooten på Pico W.

4. Kontrollera att variablerna CERT_FILE och KEY_FILE i skriptet
   pekar på rätt filvägar:

   CERT_FILE = "/cert.pem"
   KEY_FILE  = "/key.pem"

---------------------------------------------------------------
"""

import wifi
import socketpool
import ssl
import time
import asyncio

# ---------- KONFIG ----------
AP_SSID = "MyCaptivePortal"
AP_PASSWORD = "12345678"
CAPTIVE_IP = "192.168.4.1"     # den IP som DHCP/DNS pekar mot
LOGIN_TIMEOUT = 600            # sekunder
CERT_FILE = "/cert.pem"
KEY_FILE = "/key.pem"
# ----------------------------

# Enkel sessionslista: ip -> expiry_timestamp
allowed_clients = {}

def is_allowed(ip):
    if ip in allowed_clients:
        if allowed_clients[ip] > time.time():
            return True
        else:
            del allowed_clients[ip]
    return False

# Starta AP (CircuitPython)
print("Startar Access Point...")
wifi.radio.start_ap(ssid=AP_SSID, password=AP_PASSWORD)
print("AP körs. Väntar några sekunder...")
time.sleep(2)
print("AP uppe. OBS: kontrollera att DHCP ger klienter DNS =", CAPTIVE_IP)

# ------------------------------------------------------------
# DNS-HIJACK (UDP) - svarar med A-record som pekar på CAPTIVE_IP
# ------------------------------------------------------------
async def dns_hijack_server():
    print("Startar DNS-hijack på UDP/53")
    pool = socketpool.SocketPool(wifi.radio)
    sock = pool.socket(pool.AF_INET, pool.SOCK_DGRAM)
    sock.bind(("0.0.0.0", 53))
    sock.settimeout(0.5)

    def ipv4_to_bytes(ip_str):
        parts = [int(p) for p in ip_str.split('.')]
        return bytes(parts)

    while True:
        try:
            data, addr = sock.recvfrom(512)
            client = addr[0]
            tid = data[0:2]
            flags = b'\x81\x80'
            qdcount = data[4:6]
            ancount = qdcount
            nscount = b'\x00\x00'
            arcount = b'\x00\x00'
            header = tid + flags + qdcount + ancount + nscount + arcount

            query = data[12:]
            name_end = query.find(b'\x00') + 1
            if name_end <= 0:
                await asyncio.sleep(0)
                continue
            question = query[:name_end + 4]

            answer = (
                b'\xc0\x0c' +
                b'\x00\x01\x00\x01' +
                b'\x00\x00\x00\x3c' +
                b'\x00\x04' +
                ipv4_to_bytes(CAPTIVE_IP)
            )
            resp = header + question + answer
            sock.sendto(resp, addr)
        except Exception:
            await asyncio.sleep(0)
            continue

# ------------------------------------------------------------
# HTTPS-server (enkel): servar /captive.json, portal och /login (POST)
# ------------------------------------------------------------
async def https_server():
    print("Startar HTTPS-server på port 443")
    pool = socketpool.SocketPool(wifi.radio)
    server_sock = pool.socket(pool.AF_INET, pool.SOCK_STREAM)
    server_sock.bind((CAPTIVE_IP, 443))
    server_sock.listen(2)
    server_sock.settimeout(0.5)

    try:
        server_ssl = ssl.wrap_socket(server_sock, server_side=True, certfile=CERT_FILE, keyfile=KEY_FILE)
    except Exception as e:
        print("SSL-wrap på server-socket misslyckades:", e)
        server_ssl = server_sock

    while True:
        try:
            client_sock, addr = server_ssl.accept()
            if client_sock and client_sock.__class__.__name__.lower().find('ssl') == -1:
                try:
                    client_sock = ssl.wrap_socket(client_sock, server_side=True, certfile=CERT_FILE, keyfile=KEY_FILE)
                except Exception:
                    pass
            asyncio.create_task(handle_https_client(client_sock, addr))
        except Exception:
            await asyncio.sleep(0)
            continue

async def handle_https_client(conn, addr):
    client_ip = addr[0]
    try:
        req = b""
        conn.settimeout(0.5)
        try:
            req = conn.recv(2048)
        except Exception:
            pass
        if not req:
            conn.close()
            return

        text = req.decode(errors="ignore")
        first_line = text.split("\r\n", 1)[0]
        parts = first_line.split(" ")
        if len(parts) < 2:
            path = "/"
            method = "GET"
        else:
            method, path = parts[0], parts[1]

        # captive.json endpoint
        if path == "/captive.json":
            if is_allowed(client_ip):
                payload = ('HTTP/1.1 200 OK\r\n'
                           'Content-Type: application/json\r\n\r\n'
                           '{ "captive": false, "user-portal-url": "https://%s/", "seconds-remaining": 0, "can-extend-session": false }' % CAPTIVE_IP)
            else:
                payload = ('HTTP/1.1 200 OK\r\n'
                           'Content-Type: application/json\r\n\r\n'
                           '{ "captive": true, "user-portal-url": "https://%s/", "seconds-remaining": %d, "can-extend-session": true }' %
                           (CAPTIVE_IP, LOGIN_TIMEOUT))
            conn.send(payload.encode())
            conn.close()
            return

        # kontroll-URLer (Android/Windows/iOS)
        if "generate_204" in path or "connecttest.txt" in path or "captive.apple.com" in text:
            if is_allowed(client_ip):
                resp = "HTTP/1.1 204 No Content\r\n\r\n"
            else:
                resp = "HTTP/1.1 302 Found\r\nLocation: https://%s/\r\n\r\n" % CAPTIVE_IP
            conn.send(resp.encode())
            conn.close()
            return

        # POST /login
        if path.startswith("/login") and method.upper() == "POST":
            allowed_clients[client_ip] = time.time() + LOGIN_TIMEOUT
            body = ('HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n'
                    '<html><body><h3>Du är nu inloggad!</h3><p>Internet aktiverat.</p></body></html>')
            conn.send(body.encode())
            conn.close()
            return

        # Portal startsida
        if not is_allowed(client_ip):
            page = ('HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n'
                    '<html><body><h2>Välkommen till %s</h2>'
                    '<form action="/login" method="POST"><input name="user" placeholder="Användarnamn"><br>'
                    '<input type="password" name="pass" placeholder="Lösenord"><br>'
                    '<button>Logga in</button></form></body></html>') % AP_SSID
        else:
            page = ('HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n'
                    '<html><body><h3>Du är redan inloggad!</h3></body></html>')

        conn.send(page.encode())
        conn.close()
    except Exception as e:
        print("Client handler error:", e)
        try:
            conn.close()
        except Exception:
            pass

# ------------------------------------------------------------
# Starta allt i asyncio
# ------------------------------------------------------------
async def main():
    await asyncio.gather(
        dns_hijack_server(),
        https_server()
    )

# Kör
try:
    asyncio.run(main())
except Exception as e:
    print("Fel i main:", e)
