#pragma once
#include <string>

using namespace std;

typedef unsigned int (*HashFunction)(const char*);
unsigned int sdbmHash(const char *p) {
unsigned int hash = 0;
auto *str = (unsigned char *) p;
int c{};
while ((c = *str++)) {
hash = c + (hash << 6) + (hash << 16) - hash;
}
return hash;
}


/// From Cp algorithm 
