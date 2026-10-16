// AF_UNIX request effect. Blocking call on the io_work helper thread;
// read loops until the peer closes, then answers the collected bytes.
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>

#ifdef CID_HOST_UNIX_REQUEST
static void host_unix_request_call(IoWork* w) {
  const char* path = w->data;
  const char* req  = w->data + strlen(path) + 1;
  int fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (fd < 0) { io_sys_end(w, -1); return; }
  struct sockaddr_un at;
  memset(&at, 0, sizeof(at));
  at.sun_family = AF_UNIX;
  strncpy(at.sun_path, path, sizeof(at.sun_path) - 1);
  if (connect(fd, (struct sockaddr*)&at, sizeof(at)) != 0) {
    int saved = errno;
    close(fd);
    errno = saved;
    io_sys_end(w, -1);
    return;
  }
  size_t len = strlen(req);
  const char* p = req;
  while (len > 0) {
    ssize_t n = write(fd, p, len);
    if (n <= 0) { close(fd); io_sys_end(w, -1); return; }
    p += n;
    len -= (size_t)n;
  }
  shutdown(fd, SHUT_WR);
  uint64_t cap = 4096, got = 0;
  char* buf = malloc(cap);
  for (;;) {
    if (got == cap - 1) { cap *= 2; buf = realloc(buf, cap); }
    ssize_t n = read(fd, buf + got, cap - 1 - got);
    if (n < 0) { if (errno == EINTR) continue; free(buf); close(fd); io_sys_end(w, -1); return; }
    if (n == 0) break;
    got += (size_t)n;
  }
  close(fd);
  free(w->data);
  w->data = buf;
  w->size = got + 1;
  buf[got] = 0;
  w->code = 0;
}
static Term host_unix_request_pack(Env e, IoWork* w) {
  char* buf = w->data;
  if (w->code != 0) { free(buf); return io_fail(e, w->code, NULL); }
  w->data = NULL;
  return io_done(e, io_str(e, buf, w->size));
}
Term host_unix_request_run(Env e, Term* f, IoWork* w) {
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
  return io_work(w, host_unix_request_call, host_unix_request_pack);
}
static void __attribute__((constructor)) host_unix_request_use(void) {
  io_eff(CID_HOST_UNIX_REQUEST, host_unix_request_run, 0);
}
#endif
