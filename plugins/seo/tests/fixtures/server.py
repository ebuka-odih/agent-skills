"""Tiny test site for seo-crawl tests. Usage: python3 server.py <port-file> [mode] [redirect-target]
modes: main (default), clean, edge, down, v200, v301, v302, v301x"""
import http.server, socketserver, sys, time

def page(title, body, canon="", extra=""):
    c = f'<link rel="canonical" href="{canon}">' if canon else ""
    d = "A clear description of this test page that is long enough to pass the description length check."
    return (f'<!doctype html><html lang="en"><head><title>{title}</title><meta name="description" content="{d}">{c}'
            f'<meta property="og:title" content="t"><meta property="og:description" content="d"><meta property="og:image" content="BASE/og.png">'
            f'{extra}</head><body>{body}</body></html>')

LONG = "<h1>Places</h1><p>" + "Real content about places in the area. " * 10 + "</p>"
ROUTES = {
    "/": (200, {}, page("Home page of the test site", LONG, "BASE/")),
    "/a": (200, {}, page("Page A of the test site", LONG, "BASE/a")),
    "/shell": (200, {}, '<!doctype html><html lang="en"><head><title>App shell page</title></head><body><div id="root"></div><script>var x="' + "y" * 500 + '"</script></body></html>'),
    "/hidden": (200, {"X-Robots-Tag": "noindex"}, page("Hidden page of the test site", LONG, "BASE/hidden")),
    "/slow": (200, {}, page("Slow page of the test site", LONG, "BASE/slow")),
    "/old": (301, {"Location": "/a"}, ""),
    "/older": (301, {"Location": "/old"}, ""),
    "/gone": (404, {}, "not found"),
    "/robots.txt": (200, {"Content-Type": "text/plain"}, "User-agent: *\nAllow: /\n\nUser-agent: *\nDisallow: /private\nSitemap: BASE/sitemap.xml\n"),
    "/sitemap.xml": (200, {"Content-Type": "application/xml"}, '<?xml version="1.0"?><sitemapindex><sitemap><loc>BASE/sitemaps/pages.xml</loc></sitemap><sitemap><loc>BASE/sitemaps/missing.xml</loc></sitemap></sitemapindex>'),
    "/sitemaps/pages.xml": (200, {"Content-Type": "application/xml"}, "<urlset>" + "".join(f"<url><loc>BASE{p}</loc></url>" for p in ["/", "/a", "/shell", "/hidden", "/slow", "/older", "/gone"]) + "<url><loc>https://elsewhere.test/x</loc></url></urlset>"),
}

MODE = sys.argv[2] if len(sys.argv) > 2 else "main"
TARGET = sys.argv[3] if len(sys.argv) > 3 else ""
ROBOTS_OK = "User-agent: *\nDisallow: /private\nSitemap: BASE/sitemap.xml\n"
def urlset(paths): return "<urlset>" + "".join(f"<url><loc>BASE{p}</loc></url>" for p in paths) + "</urlset>"
EDGE = lambda n: "<!doctype html><html><body>" + "a" * n + "</body></html>"
if MODE == "clean":
    ROUTES = {"/": ROUTES["/"], "/a": ROUTES["/a"], "/edge200": (200, {}, EDGE(200)),
              "/robots.txt": (200, {}, ROBOTS_OK), "/sitemap.xml": (200, {}, urlset(["/", "/a", "/edge200"]))}
elif MODE == "edge":
    ROUTES = {"/": ROUTES["/"], "/a": ROUTES["/a"], "/edge199": (200, {}, EDGE(199)),
              "/old": (301, {"Location": "/a"}, ""), "/oldgone": (301, {"Location": "/gone"}, ""),
              "/robots.txt": (200, {}, "User-agent: *\nDisallow: /assets/app.js\nSitemap: BASE/sitemap.xml\n"),
              "/sitemap.xml": (200, {}, urlset(["/", "/edge199", "/old", "/oldgone"]))}
elif MODE == "many":  # 51 child sitemaps: the crawler reads at most 50
    ROUTES = {"/": ROUTES["/"], "/robots.txt": (200, {}, ROBOTS_OK),
              "/sitemap.xml": (200, {}, "<sitemapindex>" + "".join(f"<sitemap><loc>BASE/s/{i}.xml</loc></sitemap>" for i in range(1, 52)) + "</sitemapindex>")}
    for i in range(1, 52): ROUTES[f"/s/{i}.xml"] = (200, {}, urlset(["/"]))
elif MODE == "down":
    ROUTES = {"/": (503, {}, "down"), "/robots.txt": (200, {}, ROBOTS_OK), "/sitemap.xml": (200, {}, "<urlset></urlset>")}
elif MODE.startswith("v"):
    ROUTES = {}

class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        base = f"http://127.0.0.1:{self.server.server_address[1]}"
        code, headers, body = ROUTES.get(self.path.split("?")[0], (404, {}, "not found"))
        if MODE == "v200": code, headers, body = 200, {}, "<html><body>copy</body></html>"
        if MODE in ("v301", "v302"): code, headers, body = (301 if MODE == "v301" else 302), {"Location": TARGET + "/"}, ""
        if MODE == "v301x": code, headers, body = 301, {"Location": "https://elsewhere.test/"}, ""
        if self.path == "/slow": time.sleep(0.6)
        self.send_response(code)
        for k, v in headers.items(): self.send_header(k, v.replace("BASE", base) if k == "Location" and v.startswith("BASE") else v)
        self.send_header("Content-Type", headers.get("Content-Type", "text/html; charset=utf-8"))
        data = body.replace("BASE", base).encode()
        self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data)

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", 0), H) as s:
    open(sys.argv[1], "w").write(str(s.server_address[1]))
    s.serve_forever()
