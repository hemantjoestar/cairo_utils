use array::{SpanTrait, ArrayTrait};
use option::OptionTrait;
use integer::u512;
use cairo_utils::sundry::{TBitAnd, SpanPrintImpl};
use cairo_utils::math_funcs::pow_x;
use cairo_utils::array_ops::{span_pack};
use debug::PrintTrait;
use traits::{Into, TryInto};

fn get_radix_u128(mut in: Span<u8>) -> Array<u128> {
    let mut out = Default::<Array<u128>>::default();
    // constants
    // specific for hex repr 0x. 4*32 = 128
    let k = 32_usize;
    // each byte has 2 nibbles or units of 8 bytes 
    let n = 2 * in.len();
    // didnt follow formula as per 14.5
    // value indicates max limb suffix
    let l = ((n + 1) / k);
    // Short-circuit
    // Lvl 1. if needed limbs is 1 ie. len <= 32 nibbles or 16 bytes
    // no need to split into 4 bits
    if l == 0 || n == k {
        out.append(span_pack::<u8, u128>(in).unwrap());
        return out;
    } else {
        // k/2 since accounting for nibbles, and needed from bottom
        // k will always be even 
        out.append(span_pack::<u8, u128>(in.slice(in.len() - k / 2, k / 2)).unwrap());
        let mut index: usize = 0;
        loop {
            if index == k / 2 {
                break ();
            }
            //vent excess to maintain a_((i*k)+j)
            in.pop_back();
            index = index + 1_usize;
        };
    }
    // we need only 4 bits since it is initial base b. aka b = 2^4
    let b = 0x10_u128;
    loop {
        // didnt follow formula as per 14.5, empty check is same
        if in.is_empty() {
            break ();
        }
        // Inner summation for single limb
        let mut limb_i = Default::default();
        let mut index_j: usize = 0;
        loop {
            if index_j == k || in.is_empty() {
                break ();
            }
            // popping span == a_((i*k)+j).. so sorted
            let u8_unit = (*in.pop_back().unwrap()).into();
            let low_4_bits = u8_unit & 0x0F_u128;
            let high_4_bits = (u8_unit & 0xF0_u128) / 0x10_u128;
            let a_index_even = low_4_bits * pow_x::<u128>(b, index_j.try_into().unwrap());
            index_j = index_j + 1_usize;
            let a_index_odd = high_4_bits * pow_x::<u128>(b, index_j.try_into().unwrap());
            index_j = index_j + 1_usize;
            limb_i += a_index_even + a_index_odd;
        };
        out.append(limb_i);
    };
    out
}
#[cfg(test)]
mod tests {
    use array::{SpanTrait, ArrayTrait};
    use super::get_radix_u128;
    use cairo_utils::array_ops::{unpack_into};
    use debug::PrintTrait;
    #[test]
    #[available_gas(100000000)]
    fn tests_radix_u128_limb_0_limb_1() {
        let given: u256 = 0xfd187671a1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
        let mut array_u8 = Default::<Array<u8>>::default();
        unpack_into(given, ref array_u8);
        // array_u8.len().print();
        let u128_radix_array = get_radix_u128(array_u8.span());
        assert(*u128_radix_array[0] == given.low, 'limb_0 != low');
        assert(*u128_radix_array[1] == given.high, 'limb_1 != high');
    }
    #[test]
    #[available_gas(100000000)]
    fn tests_radix_u128_limb_0_limb_1_minus_leading_16bits() {
        let given: u256 = 0x7671a1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
        let mut array_u8 = Default::<Array<u8>>::default();
        unpack_into(given, ref array_u8);
        // array_u8.len().print();
        let u128_radix_array = get_radix_u128(array_u8.span());
        assert(*u128_radix_array[0] == given.low, 'limb_0 != low');
        assert(*u128_radix_array[1] == given.high, 'limb_1 != high');
    }
    #[test]
    #[available_gas(100000000)]
    fn tests_radix_u128_limb_0_limb_1_minus_trailing_16bits() {
        let given: u256 = 0xfd187671a1d5f861b976693a967019778bb2aaac30a36b419311ab63c741;
        let mut array_u8 = Default::<Array<u8>>::default();
        unpack_into(given, ref array_u8);
        // array_u8.len().print();
        let u128_radix_array = get_radix_u128(array_u8.span());
        assert(*u128_radix_array[0] == given.low, 'limb_0 != low');
        assert(*u128_radix_array[1] == given.high, 'limb_1 != high');
    }
    #[test]
    #[available_gas(5000000)]
    fn tests_radix_u128_limb_0() {
        let mut array_u8 = Default::<Array<u8>>::default();
        array_u8.append(0xAB);
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
        assert(
            *get_radix_u128(array_u8.span())[0] == 0xABCDEF1234567890ABCDEF1234567890_u128,
            'u8_into_radix_u128'
        );
    }
    #[test]
    #[available_gas(5000000)]
    fn tests_radix_u128_limb_0_less_than_16_bytes() {
        let mut array_u8 = Default::<Array<u8>>::default();
        array_u8.append(0xAB);
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
        assert(
            *get_radix_u128(array_u8.span())[0] == 0xABCDEF1234567890ABCDEF12345678_u128,
            'u8_into_radix_u128'
        );
    }
}
