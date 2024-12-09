#ifndef __MACROS_INC
#define __MACROS_INC

// https://isocpp.org/wiki/faq/misc-technical-issues#macros-with-token-pasting
#define _MERGE_IMPL(a,b) a##b
#define MERGE(a,b) _MERGE_IMPL(a,b)

#define _MERGE_IMPL(a,b,c) a##b##c
#define MERGE(a,b,c) _MERGE_IMPL(a,b,c)

#endif