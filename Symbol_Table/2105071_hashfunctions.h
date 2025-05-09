#pragma once
#include <string>

using namespace std;

typedef unsigned int (*HashFunction)(std::string, unsigned int);

unsigned int SDBMHash ( string str,unsigned int num_buckets ) {
    unsigned int hash = 0;
    unsigned int len = str.length () ;
    for ( unsigned int i = 0; i < len ; i ++)
    {
        hash = (( str [ i ]) + ( hash << 6) + ( hash << 16) - hash ) %
    num_buckets ;
    }
    return hash;
}

unsigned int DJB2Hash( string str,unsigned int num_buckets ) {
    long long hash = 5381;
    for (char ch : str) {
        hash = ((hash << 5) + hash) + ch; // hash * 33 + ch
    }
    return hash;
}

// Found at http://www.cse.yorku.ca/~oz/hash.html

unsigned int pollynomial_rolling( string str,unsigned int num_buckets ) {
    const int p = 31;
    unsigned int hash_value = 0;
    unsigned int p_pow = 1;
    for (char c : str) {
        hash_value = (hash_value + (c - 'a' + 1) * p_pow) % num_buckets;
        p_pow = (p_pow * p) % num_buckets;
    }
    return hash_value;
}

/// From Cp algorithm 
