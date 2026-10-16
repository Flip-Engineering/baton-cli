// Durability probe effects. One C half; each effect guarded by its CID.
// Patterns copied from the toolchain's effs/file_write.c and file_size.c
// (io_work for blocking calls, io_tup to hand a handle back).
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#ifdef CID_HOST_SYNC
static void host_sync_call(IoWork* w) {
  io_sys_end(w, fsync((int)w->hand));
}
static Term host_sync_pack(Env e, IoWork* w) {
  Term r = w->code ? io_fail(e, w->code, NULL) : io_done(e, term_pak(CID_UNIT, 0));
  return io_tup(e, io_hand(w->hand), r);
}
Term host_sync_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  return io_work(w, host_sync_call, host_sync_pack);
}
static void __attribute__((constructor)) host_sync_use(void) {
  io_eff(CID_HOST_SYNC, host_sync_run, 0);
}
#endif

#ifdef CID_HOST_SYNC_DIR
static void host_sync_dir_call(IoWork* w) {
  int fd = open(w->data, O_RDONLY | O_DIRECTORY);
  if (fd < 0) { io_sys_end(w, -1); return; }
  int n = fsync(fd);
  int saved = errno;
  close(fd);
  errno = saved;
  io_sys_end(w, n);
}
static Term host_sync_dir_pack(Env e, IoWork* w) {
  free(w->data);
  return w->code ? io_fail(e, w->code, NULL) : io_done(e, term_pak(CID_UNIT, 0));
}
Term host_sync_dir_run(Env e, Term* f, IoWork* w) {
  w->data = io_cstr(e, f[0], &w->size);
  return io_work(w, host_sync_dir_call, host_sync_dir_pack);
}
static void __attribute__((constructor)) host_sync_dir_use(void) {
  io_eff(CID_HOST_SYNC_DIR, host_sync_dir_run, 0);
}
#endif

#ifdef CID_HOST_RENAME
static void host_rename_call(IoWork* w) {
  const char* b = w->data;
  io_sys_end(w, rename(b, b + strlen(b) + 1));
}
static Term host_rename_pack(Env e, IoWork* w) {
  free(w->data);
  return w->code ? io_fail(e, w->code, NULL) : io_done(e, term_pak(CID_UNIT, 0));
}
Term host_rename_run(Env e, Term* f, IoWork* w) {
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
  return io_work(w, host_rename_call, host_rename_pack);
}
static void __attribute__((constructor)) host_rename_use(void) {
  io_eff(CID_HOST_RENAME, host_rename_run, 0);
}
#endif

#ifdef CID_HOST_UNLINK
static void host_unlink_call(IoWork* w) {
  io_sys_end(w, unlink(w->data));
}
static Term host_unlink_pack(Env e, IoWork* w) {
  free(w->data);
  return w->code ? io_fail(e, w->code, NULL) : io_done(e, term_pak(CID_UNIT, 0));
}
Term host_unlink_run(Env e, Term* f, IoWork* w) {
  w->data = io_cstr(e, f[0], &w->size);
  return io_work(w, host_unlink_call, host_unlink_pack);
}
static void __attribute__((constructor)) host_unlink_use(void) {
  io_eff(CID_HOST_UNLINK, host_unlink_run, 0);
}
#endif

#ifdef CID_HOST_STAT_SIZE
static void host_stat_size_call(IoWork* w) {
  struct stat st;
  int n = stat(w->data, &st);
  io_sys_end(w, n);
  if (n == 0) {
    w->code = st.st_size > (off_t)UINT32_MAX ? EOVERFLOW : 0;
    w->word = (u32)st.st_size;
  }
}
static Term host_stat_size_pack(Env e, IoWork* w) {
  free(w->data);
  return w->code ? io_fail(e, w->code, NULL) : io_done(e, w->word);
}
Term host_stat_size_run(Env e, Term* f, IoWork* w) {
  w->data = io_cstr(e, f[0], &w->size);
  return io_work(w, host_stat_size_call, host_stat_size_pack);
}
static void __attribute__((constructor)) host_stat_size_use(void) {
  io_eff(CID_HOST_STAT_SIZE, host_stat_size_run, 0);
}
#endif

#ifdef CID_HOST_MKDIR
static void host_mkdir_call(IoWork* w) {
  if (mkdir(w->data, 0755) != 0 && errno != EEXIST) {
    io_sys_end(w, -1);
  } else {
    w->code = 0;
  }
}
static Term host_mkdir_pack(Env e, IoWork* w) {
  free(w->data);
  return w->code ? io_fail(e, w->code, NULL) : io_done(e, term_pak(CID_UNIT, 0));
}
Term host_mkdir_run(Env e, Term* f, IoWork* w) {
  w->data = io_cstr(e, f[0], &w->size);
  return io_work(w, host_mkdir_call, host_mkdir_pack);
}
static void __attribute__((constructor)) host_mkdir_use(void) {
  io_eff(CID_HOST_MKDIR, host_mkdir_run, 0);
}
#endif
