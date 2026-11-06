"""Test server for uptime-scan live probes. Usage: python3 uptime_server.py <port-file> <mode>
modes: good (404 for unknown, /livez 200), soft (200 for everything), nohealth (404 everywhere), slow (/up 200 after 1.3 s)"""
import http.server, socketserver, sys, time
MODE = sys.argv[2]
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        p = self.path
        if MODE == "soft": code = 200
        elif MODE == "good": code = 200 if p in ("/", "/livez") else 404
        elif MODE == "slow":
            code = 200 if p in ("/", "/up") else 404
            if p == "/up": time.sleep(1.3)
        else: code = 200 if p == "/" else 404
        self.send_response(code); self.send_header("Content-Length", "2"); self.end_headers(); self.wfile.write(b"ok")
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", 0), H) as s:
    open(sys.argv[1], "w").write(str(s.server_address[1])); s.serve_forever()
