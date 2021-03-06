
`ifndef CLOG2_H
`define CLOG2_H

`define clog2(x) ( \
    ((x) <= (1 <<  1)) ?  1 : \
    ((x) <= (1 <<  2)) ?  2 : \
    ((x) <= (1 <<  3)) ?  3 : \
    ((x) <= (1 <<  4)) ?  4 : \
    ((x) <= (1 <<  5)) ?  5 : \
    ((x) <= (1 <<  6)) ?  6 : \
    ((x) <= (1 <<  7)) ?  7 : \
    ((x) <= (1 <<  8)) ?  8 : \
    ((x) <= (1 <<  9)) ?  9 : \
    ((x) <= (1 << 10)) ? 10 : \
    ((x) <= (1 << 11)) ? 11 : \
    ((x) <= (1 << 12)) ? 12 : \
    ((x) <= (1 << 13)) ? 13 : \
    ((x) <= (1 << 14)) ? 14 : \
    ((x) <= (1 << 15)) ? 15 : \
    ((x) <= (1 << 16)) ? 16 : \
    ((x) <= (1 << 17)) ? 17 : \
    ((x) <= (1 << 18)) ? 18 : \
    ((x) <= (1 << 19)) ? 19 : \
    ((x) <= (1 << 20)) ? 20 : \
    ((x) <= (1 << 21)) ? 21 : \
    ((x) <= (1 << 22)) ? 22 : \
    ((x) <= (1 << 23)) ? 23 : \
    ((x) <= (1 << 24)) ? 24 : \
    ((x) <= (1 << 25)) ? 25 : \
    ((x) <= (1 << 26)) ? 26 : \
    ((x) <= (1 << 27)) ? 27 : \
    ((x) <= (1 << 28)) ? 28 : \
    ((x) <= (1 << 29)) ? 29 : \
    ((x) <= (1 << 30)) ? 30 : \
    ((x) <= (1 << 31)) ? 31 : \
    ((x) <= (1 << 32)) ? 32 : -1 \
    )
    // Set to -1 if we don't support the large number
    //   to throw a syntax error

`endif
