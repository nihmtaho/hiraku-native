#ifndef HK_H
#define HK_H
#include <stdint.h>

typedef struct {
    uint8_t *data;
    uint64_t len;
} HKBytes;

typedef int64_t hk_handle;

int32_t hk_open(const char *db_path, hk_handle *out_handle, HKBytes *out_err);
int32_t hk_call(hk_handle handle, const char *method, HKBytes req, HKBytes *out_resp);
void hk_free(HKBytes bytes);
int32_t hk_close(hk_handle handle);
#endif
