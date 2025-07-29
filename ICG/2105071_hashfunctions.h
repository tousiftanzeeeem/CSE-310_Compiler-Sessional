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


/// From Cp algorithm 