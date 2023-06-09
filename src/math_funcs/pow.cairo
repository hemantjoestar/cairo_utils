use option::OptionTrait;
// Dangerous function which will fail.n many cases 
// more of a convenience for now
// Since overflow Mul panics cant do much
fn pow_2<T, impl TDrop: Drop<T>, impl U8IntoT: Into<u8, T>, impl TCopy: Copy<T>, impl TMul: Mul<T>>(
    pow: u8
) -> Option<T> {
    // 'pow'.print();
    // pow.print();
    if pow == 0 {
        return Option::Some(Into::into(1_u8));
    }
    if pow == 1 {
        return Option::Some(Into::into(2_u8));
    }
    if pow % 2 == 0 {
        match pow_2::<T>(pow / 2) {
            Option::Some(v) => Option::Some(v * v),
            Option::None(_) => Option::None(()),
        }
    } else {
        match pow_2::<T>((pow - 1) / 2) {
            Option::Some(v) => Option::Some(Into::into(2_u8) * v * v),
            Option::None(_) => Option::None(()),
        }
    }
}
#[cfg(test)]
mod tests {
    use super::pow_2;
    use option::OptionTrait;
    #[test]
    #[available_gas(10000000)]
    fn tests_pow_2() {
        assert(pow_2::<u256>(0).unwrap() == 0x1, '2pow0');
        assert(pow_2::<u8>(1).unwrap() == 0x2, '2pow1');
        assert(pow_2::<u256>(32).unwrap() == 0x100000000, '2pow32');
        assert(pow_2(32).unwrap() == 0x100000000_u256, '2pow32');
        assert(pow_2(64).unwrap() == 0x10000000000000000_u256, '2pow64');
        assert(pow_2(96).unwrap() == 0x1000000000000000000000000_u256, '2pow96');
        assert(pow_2(128).unwrap() == 0x100000000000000000000000000000000_u256, '2pow128');
        assert(pow_2(160).unwrap() == 0x10000000000000000000000000000000000000000_u256, '2pow160');
        assert(
            pow_2(192).unwrap() == 0x1000000000000000000000000000000000000000000000000_u256,
            '2pow192'
        );
        assert(
            pow_2(224).unwrap() == 0x100000000000000000000000000000000000000000000000000000000_u256,
            '2pow224'
        );
    }
}
