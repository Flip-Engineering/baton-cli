// The separately built extension library: one exported C entry.
#include <stdint.h>
#include <string.h>

int32_t ext_run(const char* input, uint32_t n) {
  if (input != NULL && strcmp(input, "seed") == 0) {
    return (int32_t)(42 + n);
  }
  return -1;
}
