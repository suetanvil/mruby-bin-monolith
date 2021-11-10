
#ifndef HDR_BARRIER_H
#define HDR_BARRIER_H

#include <stdlib.h>
#include <string.h>


// Return the barrier string.  (We store it reversed so that it
// doesn't appear in the resulting executable's data segment as-is.)
static inline char* get_barrier() {
    const char backward[] =
        "YNkUoOhjOaiJtr8yVnGhwMlMxJ28xWvR7MkaIbeV"
        "dN4OlKzJpCb7O3YMvzH00R43ujKsdlQazTmyz11e"
        "UFvbySsgEwkhOb7tmNIynBpMxDWRd4sR62YR6WwP"
        "Q5moV2JZW65KUvXNrJZRY5R2q9fpTDFIhnhmkq6M";
    size_t blen = strlen(backward);
    char *forward = calloc(1, blen + 1);

    for (size_t n = 0; n < blen; n++) {
        forward[blen - 1 - n] = backward[n];
    }

    return forward;
}

#endif
