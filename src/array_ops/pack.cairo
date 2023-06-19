use array::SpanTrait;
use array::ArrayTrait;
use option::OptionTrait;
use integer::BoundedInt;
use cairo_utils::math_funcs::pow_2;

// returns max_pack_possible, T_bit_width
trait MaxPack<T, U> {
    fn max_pack_into() -> (usize, usize);
}
impl U8MaxPackU64 of MaxPack<u8, u64> {
    fn max_pack_into() -> (usize, usize) {
        (8, 8)
    }
}
impl U8MaxPackU128 of MaxPack<u8, u128> {
    fn max_pack_into() -> (usize, usize) {
        (16, 8)
    }
}
impl U8MaxPackU256 of MaxPack<u8, u256> {
    fn max_pack_into() -> (usize, usize) {
        (32, 8)
    }
}
impl U32MaxPackU64 of MaxPack<u32, u64> {
    fn max_pack_into() -> (usize, usize) {
        (2, 32)
    }
}
impl U32MaxPackU256 of MaxPack<u32, u256> {
    fn max_pack_into() -> (usize, usize) {
        (8, 32)
    }
}
impl U64MaxPackFelt252 of MaxPack<u64, felt252> {
    fn max_pack_into() -> (usize, usize) {
        (3, 64)
    }
}
impl U64MaxPackU128 of MaxPack<u64, u128> {
    fn max_pack_into() -> (usize, usize) {
        (2, 64)
    }
}
impl U16MaxPackU128 of MaxPack<u16, u128> {
    fn max_pack_into() -> (usize, usize) {
        (8, 16)
    }
}
impl U16MaxPackU64 of MaxPack<u16, u64> {
    fn max_pack_into() -> (usize, usize) {
        (4, 16)
    }
}
// TODO: Wierd error 
// error: Trait `core::traits::TryInto::<core::integer::u32, core::integer::u8>` has multiple implementations, in: generic param TTryIntoU8, "core::integer::U32TryIntoU8"
//  --> panicable:17:11
//      match span_pack_into(in) {
//                ^**********^
//
//      }
// #[panic_with('SPAN_PACK_FAIL',span_pack)]
fn span_pack<
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
    impl TMaxPackIntoU: MaxPack<T, U>,
    impl U8IntoU: Into<u8, U>,
    impl U32TryIntoU8: TryInto<u32, u8>
>(
    mut in: Span<T>
) -> Option<U> {
    // short circuit
    if in.len() == 1_usize {
        return Option::Some(TIntoU::into(*in.at(1)));
    }
    let (max_times, T_bit_length) = TMaxPackIntoU::max_pack_into();
    if in.len() <= max_times {
        let mut output = Default::<U>::default();
        loop {
            match in.pop_front() {
                Option::Some(v) => {
                    output =
                        UBitOr::bitor(
                            output,
                            TIntoU::into(*v)
                                * pow_2::<U>(
                                    // capped by preceeding if
                                    U32TryIntoU8::try_into(in.len() * T_bit_length).unwrap()
                                )
                        );
                },
                Option::None(_) => {
                    break ();
                },
            };
        };
        return Option::Some(output);
    }
    Option::None(())
}
// T = u64, U = u8
// impl TTryIntoU8: TryInto<T, u8>,
fn unpack_into<
    T,
    U,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
    impl TMul: Mul<T>,
    impl TDiv: Div<T>,
    impl TBitAnd: BitAnd<T>,
    impl UDrop: Drop<U>,
    impl UMaxPackIntoT: MaxPack<U, T>,
    impl UIntoT: Into<U, T>,
    impl TTryIntoU: TryInto<T, U>,
    impl U8IntoT: Into<u8, T>,
    impl U32TryIntoU8: TryInto<u32, u8>,
    impl UBounded: BoundedInt<U>,
>(
    in: T, ref out: Array<U>
) {
    let (max_times, U_bit_length) = UMaxPackIntoT::max_pack_into();
    let mut index: usize = max_times;
    loop {
        if index == 0_usize {
            break ();
        }
        out
            .append(
                TTryIntoU::try_into(
                    (in / pow_2::<T>(U32TryIntoU8::try_into((index - 1) * U_bit_length).unwrap()))
                        & UIntoT::into(UBounded::max())
                )
                    .unwrap()
            );

        index = index - 1_usize;
    };
}
#[cfg(test)]
mod tests {
    use array::SpanTrait;
    use array::ArrayTrait;
    use option::OptionTrait;
    use debug::PrintTrait;
    use super::{span_pack, unpack_into};
    use cairo_utils::sundry::{SpanPrintImpl};
    #[test]
    #[available_gas(100000000)]
    fn tests_simple_sundry() {
        let given: u256 = 0xfd187671a1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
        let mut array_u8 = Default::<Array<u8>>::default();
        unpack_into(given, ref array_u8);
        assert(array_u8.len() == 32, '32 u8s in u256');
    }

    #[test]
    #[available_gas(3000000)]
    fn test_unpack_u64_u8() {
        let in = 0xABCDEF1234567890_u64;
        let mut u8_array = Default::<Array<u8>>::default();
        unpack_into(in, ref u8_array);
        assert(*u8_array[0] == 0xAB_u8, 'index 0');
        assert(*u8_array[1] == 0xCD_u8, 'index 1');
        assert(*u8_array[2] == 0xEF_u8, 'index 2');
        assert(*u8_array[3] == 0x12_u8, 'index 3');
        assert(*u8_array[4] == 0x34_u8, 'index 4');
        assert(*u8_array[5] == 0x56_u8, 'index 5');
        assert(*u8_array[6] == 0x78_u8, 'index 6');
        assert(*u8_array[7] == 0x90_u8, 'index 7');
        assert(u8_array.len() == 8, 'u8_array len!=8');
        let in = 0xABCDEF_u64;
        unpack_into(in, ref u8_array);
        assert(*u8_array[8] == 0x00_u8, 'index 8');
        assert(*u8_array[9] == 0x00_u8, 'index 9');
        assert(*u8_array[10] == 0x00_u8, 'index 10');
        assert(*u8_array[11] == 0x00_u8, 'index 11');
        assert(*u8_array[12] == 0x00_u8, 'index 12');
        assert(*u8_array[13] == 0xAB_u8, 'index 13');
        assert(*u8_array[14] == 0xCD_u8, 'index 14');
        assert(*u8_array[15] == 0xEF_u8, 'index 15');
        assert(u8_array.len() == 16, 'u8_array len!=16');
    }
    #[test]
    #[available_gas(3000000)]
    fn test_unpack_u64_u16() {
        let in = 0xABCDEF1234567890_u64;
        let mut u16_array = Default::<Array<u16>>::default();
        unpack_into(in, ref u16_array);
        assert(u16_array.len() == 4, 'u16_array len!=4');
        assert(*u16_array[0] == 0xABCD_u16, 'index 0');
        assert(*u16_array[1] == 0xEF12_u16, 'index 1');
        assert(*u16_array[2] == 0x3456_u16, 'index 2');
        assert(*u16_array[3] == 0x7890_u16, 'index 3');
        let in = 0xABCDEF_u64;
        unpack_into(in, ref u16_array);
        assert(*u16_array[4] == 0x0000_u16, 'index 4');
        assert(*u16_array[5] == 0x0000_u16, 'index 5');
        assert(*u16_array[6] == 0x00AB_u16, 'index 6');
        assert(*u16_array[7] == 0xCDEF_u16, 'index 7');
        assert(u16_array.len() == 8, 'u16_array len!=8');
    }
    #[test]
    #[available_gas(6000000)]
    fn tests_pack_into_u256() {
        let mut array_u32 = Default::<Array<u32>>::default();
        // array_u32.append(4246238833);
        array_u32.append(2715154529);
        array_u32.append(3111545146);
        array_u32.append(2523928951);
        array_u32.append(2343742124);
        array_u32.append(816016193);
        array_u32.append(2467408739);
        array_u32.append(3342985673);
        let hash: u256 = span_pack(array_u32.span()).unwrap();
        // let hash: u256 = U32ArrayPackIntoU256::<u32, u256>::pack_into(@array_u32, 8).unwrap();
        let precomputed_hash: u256 = // 0xfd187671a1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
        0xa1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
        assert(hash == precomputed_hash, 'Hash starknet Match fail');
    // let hash: u64 = span_pack(array_u32.span()).unwrap();
    }
    #[test]
    #[available_gas(6000000)]
    fn tests_pack_u32_into_u64() {
        let mut array_u32 = Default::<Array<u32>>::default();
        // array_u32.append(4246238833);
        array_u32.append(0xABCDEF12);
        array_u32.append(0x34567890);
        let packed: u64 = span_pack(array_u32.span()).unwrap();
        assert(packed == 0xABCDEF1234567890_u64, 'u32 into u64');
    }
    #[test]
    #[available_gas(6000000)]
    fn tests_pack_u8_into_u64() {
        let mut array_u8 = Default::<Array<u8>>::default();
        // array_u32.append(4246238833);
        array_u8.append(0xAB);
        array_u8.append(0xCD);
        array_u8.append(0xEF);
        array_u8.append(0x12);
        let packed: u64 = span_pack(array_u8.span()).unwrap();
        assert(packed == 0xABCDEF12_u64, 'u32 into u64');
    }
    #[test]
    #[available_gas(6000000)]
    fn tests_pack_u16_into_u128() {
        let mut array_u16 = Default::<Array<u16>>::default();
        // array_u32.append(4246238833);
        array_u16.append(0xABCD);
        array_u16.append(0xEF12);
        array_u16.append(0x3456);
        array_u16.append(0x7890);
        let packed: u128 = span_pack(array_u16.span()).unwrap();
        assert(packed == 0xABCDEF1234567890_u128, 'u16 into u128');
    }
    #[test]
    #[available_gas(6000000)]
    fn tests_pack_u8_into_u128() {
        let mut array_u8 = Default::<Array<u8>>::default();
        // array_u8.append(0xAB);
        array_u8.append(0xCD);
        array_u8.append(0xEF);
        array_u8.append(0x12);
        array_u8.append(0x34);
        array_u8.append(0x56);
        array_u8.append(0x78);
        array_u8.append(0x90);
        array_u8.append(0xAB);
        array_u8.append(0xCD);
        array_u8.append(0xEF);
        array_u8.append(0x12);
        array_u8.append(0x34);
        array_u8.append(0x56);
        array_u8.append(0x78);
        array_u8.append(0x90);
        let packed: u128 = span_pack(array_u8.span()).unwrap();
        // assert(packed == 0xABCDEF1234567890ABCDEF1234567890_u128, 'u8 into u128');
        assert(packed == 0xCDEF1234567890ABCDEF1234567890_u128, 'u8 into u128');
    }
}
