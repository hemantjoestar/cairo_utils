use array::ArrayTrait;
use array::SpanTrait;
use serde::Serde;
use option::OptionTrait;
use traits::TryInto;
use traits::Into;
use debug::PrintTrait;


impl SpanPrintImpl<
    T, impl TPrint: debug::PrintTrait<T>, impl TCopy: Copy<T>
> of PrintTrait<Span<T>> {
    fn print(mut self: Span<T>) {
        loop {
            if self.is_empty() {
                break ();
            }
            (*(self.pop_front().unwrap())).print();
        };
    }
}

fn copy_into_wide<
    T,
    U,
    impl TCopy: Copy<T>,
    impl TDrop: Drop<T>,
    impl UCopy: Copy<U>,
    impl UDrop: Drop<U>,
    impl TIntoU: Into<T, U>
>(
    mut in: Span<T>, ref out: Array<U>
) {
    loop {
        if in.is_empty() {
            break ();
        }
        out.append(TIntoU::into(*(in.pop_front().unwrap())));
    };
}
fn move_into_wide<
    T,
    U,
    impl TCopy: Copy<T>,
    impl TDrop: Drop<T>,
    impl UCopy: Copy<U>,
    impl UDrop: Drop<U>,
    impl TIntoU: Into<T, U>
>(
    mut in: Array<T>, ref out: Array<U>
) {
    loop {
        if in.is_empty() {
            break ();
        }
        out.append(TIntoU::into(in.pop_front().unwrap()));
    };
}
#[panic_with('COPY_NARROW_ERROR', copy_into_narrow)]
fn narrow_copy<
    T,
    U,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
    impl UDrop: Drop<U>,
    impl TTryIntoU: TryInto<T, U>,
>(
    mut in: Span<T>, ref out: Array<U>
) -> Option<()> {
    let mut return_none = false;
    loop {
        if in.is_empty() {
            break ();
        }
        match TTryIntoU::try_into(*(in.pop_front().unwrap())) {
            Option::Some(u) => out.append(u),
            Option::None(_) => {
                return_none = true;
                break ();
            }
        };
    };
    if return_none {
        return Option::None(());
    }
    Option::Some(())
}
#[panic_with('MOVE_NARROW_ERROR', move_into_narrow)]
fn narrow_move<
    T,
    U,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
    impl UDrop: Drop<U>,
    impl TTryIntoU: TryInto<T, U>,
>(
    mut in: Array<T>, ref out: Array<U>
) -> Option<()> {
    let mut return_none = false;
    loop {
        if in.is_empty() {
            break ();
        }
        match TTryIntoU::try_into(in.pop_front().unwrap()) {
            Option::Some(u) => out.append(u),
            Option::None(_) => {
                return_none = true;
                break ();
            }
        };
    };
    if return_none {
        return Option::None(());
    }
    Option::Some(())
}
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

trait PackInto<T, U> {
    fn pack_into(self: @Array<T>, hint: usize) -> Option<U>;
}
// impl U32ArrayPackIntoU256 of PackInto<u32, u256> {
impl U32ArrayPackIntoU256<
    T,
    U,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
    impl UCopy: Copy<U>,
    impl UDrop: Drop<U>,
    impl UMul: Mul<U>,
    impl UBitOr: BitOr<U>,
    impl UDefault: Default<U>,
    impl TIntoU: Into<T, U>,
    impl U8IntoU: Into<u8, U>,
    impl TTryIntoU8: TryInto<u32, u8>
> of PackInto<T, U> {
    fn pack_into(self: @Array<T>, hint: usize) -> Option<U> {
        // short circuit
        if self.len() == 1_usize {
            return Option::Some(TIntoU::into(*self.at(1)));
        }
        if self.len() <= hint {
            let mut tmp_span = self.span();
            let mut output = Default::<U>::default();
            loop {
                if tmp_span.is_empty() {
                    break ();
                }
                output = output
                    | (TIntoU::into(*(tmp_span.pop_front().unwrap()))
                        * pow_2::<U>(TTryIntoU8::try_into(tmp_span.len()).unwrap() * 32).unwrap());
            };
            return Option::Some(output);
        }
        Option::None(())
    }
}
#[cfg(test)]
mod tests {
    use super::{SpanPrintImpl, copy_into_narrow, move_into_narrow, copy_into_wide, move_into_wide};
    use array::ArrayTrait;
    use array::SpanTrait;
    use debug::PrintTrait;
    use option::OptionTrait;
    use super::pow_2;
    use super::PackInto;
    use super::U32ArrayPackIntoU256;

    #[test]
    #[available_gas(6000000)]
    fn tests_pack() {
        let mut array_u32 = Default::<Array<u32>>::default();
        // array_u32.append(4246238833);
        array_u32.append(2715154529);
        array_u32.append(3111545146);
        array_u32.append(2523928951);
        array_u32.append(2343742124);
        array_u32.append(816016193);
        array_u32.append(2467408739);
        array_u32.append(3342985673);
        let hash: u256 = array_u32.pack_into(8).unwrap();
        // let hash: u256 = U32ArrayPackIntoU256::<u32, u256>::pack_into(@array_u32, 8).unwrap();
        hash.print();
        let precomputed_hash: u256 =
            // 0xfd187671a1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
            0xa1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
        assert(hash == precomputed_hash, 'Hash starknet Match fail');
    }
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
    #[test]
    #[available_gas(1000000)]
    #[should_panic(expected: ('COPY_NARROW_ERROR', ))]
    fn tests_copy_error() {
        let mut u16array = Default::<Array<u16>>::default();
        u16array.append(1_u16);
        u16array.append(256_u16);
        let mut u8array = Default::<Array<u8>>::default();
        copy_into_narrow(u16array.span(), ref u8array);
    }
    #[test]
    #[available_gas(1000000)]
    #[should_panic(expected: ('MOVE_NARROW_ERROR', ))]
    fn tests_move_error() {
        let mut u16array = Default::<Array<u16>>::default();
        u16array.append(1_u16);
        u16array.append(256_u16);
        let mut u8array = Default::<Array<u8>>::default();
        move_into_narrow(u16array, ref u8array);
    }
    #[test]
    #[available_gas(1000000)]
    fn tests_copy() {
        let mut u16array = Default::default();
        u16array.append(1_u16);
        u16array.append(1_u16);
        let mut u8array = Default::<Array<u8>>::default();
        copy_into_narrow(u16array.span(), ref u8array);
        copy_into_narrow(u16array.span(), ref u8array);
        let mut u32array = Default::default();
        u32array.append(255_u32);
        u32array.append(255_u32);
        copy_into_narrow(u32array.span(), ref u8array);
        assert(u8array.len() == 6_usize, 'size error');
    }
    #[test]
    #[available_gas(1000000)]
    fn tests_move() {
        let mut u16array = Default::default();
        u16array.append(1_u16);
        u16array.append(1_u16);
        let mut u8array = Default::<Array<u8>>::default();
        move_into_narrow(u16array, ref u8array);
        // move_into_narrow(u16array, ref u8array); //Move Error as expected
        let mut u32array = Default::default();
        u32array.append(255_u32);
        u32array.append(255_u32);
        move_into_narrow(u32array, ref u8array);
        // move_into_narrow(u32array, ref u8array); //Move Error as expected
        assert(u8array.len() == 4_usize, 'size error');
    }
// #[test]
// #[should_panic]
// #[available_gas(1000000)]
// fn test_move_panic() {
//     let mut u16array = Default::default();
//     u16array.append(1_u16);
//     u16array.append(256_u16);
//     let u8_array: Array<u8> = u16array.clone().move_into_narrow().unwrap();
// }
// #[test]
// #[ignore]
// #[available_gas(1000000)]
// #[should_panic(expected: ('Copy Error', ))]
// // #[should_panic]
// fn three() {
//     let mut u16array = Default::default();
//     u16array.append(1_u16);
//     u16array.append(256_u16);
//     let mut u32array = Default::<Array<u32>>::default();
//     move_into_wide(u16array, u32array);
// // copy_array_func::<u16, u8>(u16array,ref u8array);
// // copy_array_func::<u16, u32>(u16array, ref u8array);
// // panic_with_testa:<u16, u8>(u16array); // Moved error as expected
// // panic_with_test_1::<u16, u8>(u16array); // Moved error as expected
// }
}

