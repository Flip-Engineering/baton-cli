// dlopen effect: load a library at runtime and call its entry.
#include <dlfcn.h>
#include <stdint.h>
#include <errno.h>

typedef int32_t (*ext_fn)(const char*, uint32_t);

#ifdef CID_HOST_EXT_CALL
static void host_ext_call_impl(IoWork* w) {
  const char* path  = w->data;
  const char* input = w->data + strlen(path) + 1;
  uint32_t n = w->word;
  void* h = dlopen(path, RTLD_NOW | RTLD_LOCAL);
  if (h == NULL) { w->code = ENOENT; return; }
  ext_fn fn = (ext_fn)dlsym(h, "ext_run");
  if (fn == NULL) { dlclose(h); w->code = EINVAL; return; }
  int32_t r = fn(input, n);
  dlclose(h);
  w->code = 0;
  w->word = (uint32_t)(int64_t)r;
}
static void host_ext_call_call(IoWork* w) {
  host_ext_call_impl(w);
}
static Term host_ext_call_pack(Env e, IoWork* w) {
  free(w->data);
  return w->code ? io_fail(e, w->code, NULL) : io_done(e, w->word);
}
Term host_ext_call_run(Env e, Term* f, IoWork* w) {
  uint64_t n1 = 0, n2 = 0;
  char* a = io_cstr(e, f[0], &n1);
  char* b = io_cstr(e, f[1], &n2);
  w->size = n1 + 1 + n2 + 1;  /* io_cstr's length excludes the NUL */
  w->data = io_mem(malloc(w->size));
  memcpy(w->data, a, n1);
  ((char*)w->data)[n1] = 0;
  memcpy((char*)w->data + n1 + 1, b, n2);
  ((char*)w->data)[n1 + 1 + n2] = 0;
  free(a);
  free(b);
  w->word = (uint32_t)f[2];
  return io_work(w, host_ext_call_call, host_ext_call_pack);
}
static void __attribute__((constructor)) host_ext_call_use(void) {
  io_eff(CID_HOST_EXT_CALL, host_ext_call_run, 0);
}
#endif
