#ifndef HK_BRIDGE_H
#define HK_BRIDGE_H
#include <stdint.h>

// Declarations mirror core/ffi; symbols come from the linked Hiraku archive.

typedef struct {
    uint8_t *data;
    uint64_t len;
} HKBytes;

typedef int64_t hk_handle;

int32_t hk_open(const char *db_path, hk_handle *out_handle, HKBytes *out_err);
int32_t hk_call(hk_handle handle, const char *method, HKBytes req, HKBytes *out_resp);
void hk_free(HKBytes bytes);
int32_t hk_close(hk_handle handle);

// Spike-only harness helpers (S-8 measurements), not part of the ADR-21 ABI.
uint64_t hksample_time_ns(void);
uint64_t hksample_rss_kb(void);

#endif
