// JS halves for the durability probe (interpreter lane).
const fs = require("node:fs");

function host_sync(file) {
  try { fs.fsyncSync(file); return io_tup(file, io_done({ $: "Unit" })); }
  catch (e) { return io_tup(file, io_fail(Math.abs(e.errno ?? 5))); }
}
function host_sync_dir(path) {
  try {
    const fd = fs.openSync(path, fs.constants.O_RDONLY | fs.constants.O_DIRECTORY);
    try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
    return io_done({ $: "Unit" });
  } catch (e) { return io_fail(Math.abs(e.errno ?? 5)); }
}
function host_rename(a, b) {
  try { fs.renameSync(a, b); return io_done({ $: "Unit" }); }
  catch (e) { return io_fail(Math.abs(e.errno ?? 5)); }
}
function host_unlink(p) {
  try { fs.unlinkSync(p); return io_done({ $: "Unit" }); }
  catch (e) { return io_fail(Math.abs(e.errno ?? 5)); }
}
function host_stat_size(p) {
  try {
    const n = fs.statSync(p).size;
    return n > 4294967295 ? io_fail(75) : io_done(n);
  } catch (e) { return io_fail(Math.abs(e.errno ?? 5)); }
}
function host_mkdir(p) {
  try { fs.mkdirSync(p); return io_done({ $: "Unit" }); }
  catch (e) {
    if (e.code === "EEXIST") return io_done({ $: "Unit" });
    return io_fail(Math.abs(e.errno ?? 5));
  }
}
