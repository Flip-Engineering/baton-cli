// JS half: process.dlopen through bun:ffi is out of scope for the probe;
// the interpreter lane answers with a clear failure instead.
function host_ext_call(path, input, n) {
  return io_fail(38);
}
