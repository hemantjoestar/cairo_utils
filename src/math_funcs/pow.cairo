use option::OptionTrait;
// Dangerous function which will fail.n many cases 
// more of a convenience for now
// Since overflow Mul panics cant do much
fn pow_2<T, impl TDrop: Drop<T>, impl U8IntoT: Into<u8, T>, impl TCopy: Copy<T>, impl TMul: Mul<T>>(
    pow: u8
) -> T {
    // 'pow'.print();
    // pow.print();
    if pow == 0 {
        return Into::into(1_u8);
    }
    if pow == 1 {
        return Into::into(2_u8);
    }
    if pow % 2 == 0 {
        let v = pow_2::<T>(pow / 2);
        v * v
    } else {
        let v = pow_2::<T>((pow - 1) / 2);
        Into::into(2_u8) * v * v
    }
}
// Super Dangerous function which will fail
// for a powers use above more leeway before exploding
// more of a convenience for now
// Since overflow Mul panics cant do much
fn pow_x<T, impl TDrop: Drop<T>, impl U8IntoT: Into<u8, T>, impl TCopy: Copy<T>, impl TMul: Mul<T>>(
    x: T, pow: u8
) -> T {
    if pow == 0 {
        return Into::into(1_u8);
    }
    if pow == 1 {
        return x;
    }
    if pow % 2 == 0 {
        let v = pow_x::<T>(x, pow / 2);
        v * v
    } else {
        let v = pow_x::<T>(x, (pow - 1) / 2);
        x * v * v
    }
}
#[cfg(test)]
mod tests {
    use super::{pow_2, pow_x};
    use option::OptionTrait;
    #[test]
    #[available_gas(1000000)]
    fn pow_0x10() {
        assert(pow_x::<u128>(0x10, 0) == 0x1, '0x10pow0');
        assert(pow_x::<u128>(0x10, 1) == 0x10, '0x10pow1');
        assert(pow_x::<u128>(0x10, 2) == 0x100, '0x10pow2');
        assert(pow_x::<u128>(0x10, 3) == 0x1000, '0x10pow3');
        assert(pow_x::<u128>(0x10, 4) == 0x10000, '0x10pow4');
        assert(pow_x::<u128>(0x10, 5) == 0x100000, '0x10pow5');
        assert(pow_x::<u128>(0x10, 6) == 0x1000000, '0x10pow6');
        assert(pow_x::<u128>(0x10, 31) == 0x10000000000000000000000000000000, '0x10pow6');
    }
    #[test]
    #[available_gas(1000000)]
    fn pow_3() {
        assert(pow_x::<u256>(3, 0) == 0x1_u256, '3pow0');
        assert(pow_x::<u8>(3, 0) == 0x1_u8, '3pow0');
        assert(pow_x::<u8>(3, 1) == 0x3_u8, '3pow1');
        assert(pow_x::<u8>(3, 2) == 0x9_u8, '3pow2');
        assert(pow_x::<u8>(3, 3) == 27_u8, '3pow3');
        assert(pow_x::<u8>(3, 4) == 81_u8, '3pow4');
        assert(pow_x::<u8>(3, 5) == 243_u8, '3pow5');
        assert(pow_x::<u16>(3, 6) == 729_u16, '3pow6');
    }
    #[test]
    #[available_gas(10000000)]
    fn tests_pow_2_x() {
        assert(pow_x::<u256>(2, 0) == 0x1, '2pow0');
        assert(pow_x::<u8>(2, 1) == 0x2, '2pow1');
        assert(pow_x::<u256>(2, 32) == 0x100000000, '2pow32');
        assert(pow_x(2, 32) == 0x100000000_u256, '2pow32');
        assert(pow_x(2, 64) == 0x10000000000000000_u256, '2pow64');
        assert(pow_x(2, 96) == 0x1000000000000000000000000_u256, '2pow96');
        assert(pow_x(2, 128) == 0x100000000000000000000000000000000_u256, '2pow128');
        assert(pow_x(2, 160) == 0x10000000000000000000000000000000000000000_u256, '2pow160');
        assert(
            pow_x(2, 192) == 0x1000000000000000000000000000000000000000000000000_u256, '2pow192'
        );
        assert(
            pow_x(2, 224) == 0x100000000000000000000000000000000000000000000000000000000_u256,
            '2pow224'
        );
    }
    #[test]
    #[available_gas(10000000)]
    fn tests_pow_2() {
        assert(pow_2::<u256>(0) == 0x1, '2pow0');
        assert(pow_2::<u8>(1) == 0x2, '2pow1');
        assert(pow_2::<u256>(32) == 0x100000000, '2pow32');
        assert(pow_2(32) == 0x100000000_u256, '2pow32');
        assert(pow_2(64) == 0x10000000000000000_u256, '2pow64');
        assert(pow_2(96) == 0x1000000000000000000000000_u256, '2pow96');
        assert(pow_2(128) == 0x100000000000000000000000000000000_u256, '2pow128');
        assert(pow_2(160) == 0x10000000000000000000000000000000000000000_u256, '2pow160');
        assert(pow_2(192) == 0x1000000000000000000000000000000000000000000000000_u256, '2pow192');
        assert(
            pow_2(224) == 0x100000000000000000000000000000000000000000000000000000000_u256,
            '2pow224'
        );
    }
}
