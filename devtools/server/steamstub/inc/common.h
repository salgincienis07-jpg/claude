// shim for ReHLDS' Steam SDK headers (matchmakingtypes.h includes "common.h" for Q_* helpers)
#pragma once
#include <stdio.h>
#include <string.h>
#define Q_snprintf snprintf
#define Q_strlen strlen
