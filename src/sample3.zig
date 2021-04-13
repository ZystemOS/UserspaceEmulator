export fn sample3() u32 {
    var o: u32 = 1;
    o <<= 3;
    o &= 7;
    return o;
}
