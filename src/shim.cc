// What the JavaScript wrapper needs beyond z3's C API.

#include "z3.h"

static void ignore_error(Z3_context, Z3_error_code) {}

// z3's default error handler exits the process, which ends the WebAssembly instance. With this
// one, an error is reported in the reply instead (`(error "…")`).
extern "C" void set_noop_error_handler(Z3_context ctx) {
  Z3_set_error_handler(ctx, ignore_error);
}
