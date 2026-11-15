from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from functools import partial
from pathlib import Path
import sys,time
class Handler(SimpleHTTPRequestHandler):
 def do_GET(self):
  if self.path=='/truncated.zip':
   self.send_response(200);self.end_headers();self.wfile.write(b'partial');return
  if self.path=='/slow.zip':
   raw=(Path(self.directory)/'4/TheAllotment-Windows-0.3.4.zip').read_bytes()
   self.send_response(200);self.send_header('Content-Length',str(len(raw)));self.end_headers()
   try:
    self.wfile.write(raw[:10]);self.wfile.flush();time.sleep(2);self.wfile.write(raw[10:])
   except (BrokenPipeError,ConnectionResetError): pass
   return
  super().do_GET()
 def log_message(self,*args): pass
ThreadingHTTPServer(('127.0.0.1',int(sys.argv[2])),partial(Handler,directory=sys.argv[1])).serve_forever()
