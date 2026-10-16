// JS half: AF_UNIX request via node:net.
function host_unix_request(path, request) {
  const net = require("node:net");
  return io_park_on(null, null, (k) => {
    const s = net.createConnection({ path });
    let out = "";
    s.on("connect", () => s.write(request));
    s.on("data", (d) => { out += d.toString(); });
    s.on("end", () => { k(io_done(out)); s.destroy(); });
    s.on("error", (e) => { k(io_fail(Math.abs(e.errno ?? 5))); });
    return undefined;
  });
}
