#include "Rcpp.h"
#ifndef UTILS_H
#define UTILS_H

template<typename T>
Rcpp::StringVector makeStringVector(T start, T end) {
    Rcpp::StringVector output(end-start);
    Rcpp::StringVector::iterator oIt=output.begin();
    while (start!=end) {
        (*oIt)=*start;
        ++start;
        ++oIt;
    }
    return output;
}   

template<typename T>
int checkByVector(T start, T end) {
    if (start==end) {
        return 0;
    }
    int total=1;
    T next=start; 
    ++next;
    while (next!=end) { 
        if (*next < *start) {
            throw std::runtime_error("vector of cluster ids should be sorted");
        } else if (*next != *start) {
            ++total;
        }
        ++next;
        ++start;
    }
    return total;
}

#endif
