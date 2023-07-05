use array::{SpanTrait, ArrayTrait};
use option::OptionTrait;
use integer::u512;
use cairo_utils::sundry::{SpanPrintImpl};
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
    use integer::u512;
    use serde::Serde;
    use option::OptionTrait;

    #[test]
    #[available_gas(100000000)]
    fn tests_u512_against_prepared() {
        let lhs = 0x05191A6B52C1C090181C7B23BB5642C4A877304D19C7947946803102C632AB9A_u256;
        let rhs = 0x1D63162E7E87B730EB9E6EE7C5E60A1F29DFB53E17BE04D5BB989DA8819F578E_u256;
        let mut u8_array = Default::<Array<u8>>::default();
        u8_array.append(0x0);
        u8_array.append(0x95);
        u8_array.append(0xD1);
        u8_array.append(0x24);
        u8_array.append(0x75);
        u8_array.append(0x2D);
        u8_array.append(0xFB);
        u8_array.append(0x6);
        u8_array.append(0xFC);
        u8_array.append(0x6E);
        u8_array.append(0x69);
        u8_array.append(0x1D);
        u8_array.append(0x29);
        u8_array.append(0xBA);
        u8_array.append(0xC);
        u8_array.append(0x28);
        u8_array.append(0x8D);
        u8_array.append(0x70);
        u8_array.append(0x71);
        u8_array.append(0x8A);
        u8_array.append(0x2E);
        u8_array.append(0x6F);
        u8_array.append(0xB9);
        u8_array.append(0x39);
        u8_array.append(0xE6);
        u8_array.append(0x60);
        u8_array.append(0xF5);
        u8_array.append(0xF6);
        u8_array.append(0x2D);
        u8_array.append(0xC3);
        u8_array.append(0x92);
        u8_array.append(0x23);
        u8_array.append(0x4E);
        u8_array.append(0x68);
        u8_array.append(0x74);
        u8_array.append(0x2);
        u8_array.append(0x33);
        u8_array.append(0xFC);
        u8_array.append(0x4B);
        u8_array.append(0x72);
        u8_array.append(0x33);
        u8_array.append(0x48);
        u8_array.append(0x1);
        u8_array.append(0x7F);
        u8_array.append(0x9C);
        u8_array.append(0xCC);
        u8_array.append(0x4C);
        u8_array.append(0xB1);
        u8_array.append(0x1E);
        u8_array.append(0xFA);
        u8_array.append(0xCD);
        u8_array.append(0xC4);
        u8_array.append(0x5B);
        u8_array.append(0xC1);
        u8_array.append(0xB2);
        u8_array.append(0x7C);
        u8_array.append(0x8);
        u8_array.append(0x49);
        u8_array.append(0xD1);
        u8_array.append(0xE6);
        u8_array.append(0x57);
        u8_array.append(0x12);
        u8_array.append(0x85);
        u8_array.append(0x6C);
        assert(u8_array.len() == 64, 'input len incorrect');
        let mut u128_radix_array = get_radix_u128(u8_array.span());
        let result = u512 {
            limb0: u128_radix_array.pop_front().unwrap(),
            limb1: u128_radix_array.pop_front().unwrap(),
            limb2: u128_radix_array.pop_front().unwrap(),
            limb3: u128_radix_array.pop_front().unwrap(),
        };
        let prepared = u512 {
            limb0: 0x1EFACDC45BC1B27C0849D1E65712856C,
            limb1: 0x4E68740233FC4B723348017F9CCC4CB1,
            limb2: 0x8D70718A2E6FB939E660F5F62DC39223,
            limb3: 0x0095D124752DFB06FC6E691D29BA0C28,
        };
        assert(result == prepared, 'u512 check fail');

        // Another u512
        let lhs = 0x56CF6B29B9ABCC3507D9FA4C08AEE93A0FC2479F810E926AC6689A057C790193_u256;
        let rhs = 0x42FD1C0A816CAE53630D75B648E333775A79BF4D680B7B85B4035232BFFC4DD9_u256;
        let mut u8_array = Default::<Array<u8>>::default();
        u8_array.append(0x16);
        u8_array.append(0xB7);
        u8_array.append(0x4E);
        u8_array.append(0x1F);
        u8_array.append(0xE9);
        u8_array.append(0xD0);
        u8_array.append(0xE8);
        u8_array.append(0xFD);
        u8_array.append(0x5);
        u8_array.append(0x51);
        u8_array.append(0x83);
        u8_array.append(0xE1);
        u8_array.append(0x24);
        u8_array.append(0x2C);
        u8_array.append(0xAD);
        u8_array.append(0x41);
        u8_array.append(0x7D);
        u8_array.append(0xE5);
        u8_array.append(0x27);
        u8_array.append(0x38);
        u8_array.append(0x48);
        u8_array.append(0xF8);
        u8_array.append(0x62);
        u8_array.append(0x7C);
        u8_array.append(0x2A);
        u8_array.append(0xA9);
        u8_array.append(0x54);
        u8_array.append(0xD7);
        u8_array.append(0x12);
        u8_array.append(0x60);
        u8_array.append(0x89);
        u8_array.append(0x76);
        u8_array.append(0x9);
        u8_array.append(0x37);
        u8_array.append(0x19);
        u8_array.append(0xA8);
        u8_array.append(0x12);
        u8_array.append(0x3A);
        u8_array.append(0x4E);
        u8_array.append(0x8A);
        u8_array.append(0x5C);
        u8_array.append(0xDF);
        u8_array.append(0xFC);
        u8_array.append(0x97);
        u8_array.append(0xB);
        u8_array.append(0x93);
        u8_array.append(0xA9);
        u8_array.append(0xB7);
        u8_array.append(0x4C);
        u8_array.append(0x3A);
        u8_array.append(0x95);
        u8_array.append(0x3F);
        u8_array.append(0x15);
        u8_array.append(0xD1);
        u8_array.append(0x67);
        u8_array.append(0xE7);
        u8_array.append(0xCD);
        u8_array.append(0x1F);
        u8_array.append(0x69);
        u8_array.append(0x17);
        u8_array.append(0x21);
        u8_array.append(0xBF);
        u8_array.append(0x8C);
        u8_array.append(0x9B);
        assert(u8_array.len() == 64, 'input len incorrect');
        let mut u128_radix_array = get_radix_u128(u8_array.span());
        let result = u512 {
            limb0: u128_radix_array.pop_front().unwrap(),
            limb1: u128_radix_array.pop_front().unwrap(),
            limb2: u128_radix_array.pop_front().unwrap(),
            limb3: u128_radix_array.pop_front().unwrap(),
        };

        let result = integer::u256_wide_mul(lhs, rhs);
        let prepared = u512 {
            limb0: 0x4C3A953F15D167E7CD1F691721BF8C9B,
            limb1: 0x093719A8123A4E8A5CDFFC970B93A9B7,
            limb2: 0x7DE5273848F8627C2AA954D712608976,
            limb3: 0x16B74E1FE9D0E8FD055183E1242CAD41,
        };
        assert(result == prepared, 'u512 check fail');
    }

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
