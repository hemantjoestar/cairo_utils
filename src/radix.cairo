use array::{SpanTrait, ArrayTrait};
use option::OptionTrait;
use integer::u512;
use cairo_utils::sundry::{TBitAnd, SpanPrintImpl};
use cairo_utils::math_funcs::pow_x;
use debug::PrintTrait;
use traits::{Into, TryInto};

fn get_radix_u128(mut in: Span<u8>) -> Array<u128> {
    let mut out = Default::<Array<u128>>::default();
    // constants
    // specific for hex repr 0x.
    let k = 32_usize;
    // each byte has 2 nibbles
    let n = 2 * in.len();
    let l = ((n + 1) / k);
    l.print();
    // we need only 4 bits since it is initial base b. aka b = 2^4
    let b = 0x10_u128;
    let mut index_i: usize = 0;
    loop {
        if index_i == l || in.is_empty() {
            break ();
        }
        // Inner summation for single limb
        let mut limb_i = Default::default();
        let mut index_j: usize = 0;
        loop {
            if index_j == k || in.is_empty() {
                break ();
            }
            let u8_unit = (*in.pop_back().unwrap()).into();
            let low_4_bits = u8_unit & 0x0F_u128;
            let high_4_bits = (u8_unit & 0xF0_u128) / 0x10_u128;
            let a_index_even = low_4_bits
                * (pow_x::<u128>(b, index_j.try_into().unwrap()).unwrap());
            index_j = index_j + 1_usize;
            let a_index_odd = high_4_bits
                * (pow_x::<u128>(b, index_j.try_into().unwrap()).unwrap());
            index_j = index_j + 1_usize;
            limb_i += a_index_even + a_index_odd;
        // limb_i.print();
        };
        out.append(limb_i);

        index_i = index_i + 1_usize;
    };

    out
// let out = u512 { limb0: 0x0, limb1: 0x0, limb2: 0x0, limb3: 0x0,  };
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
        array_u8.len().print();
        let u128_radix_array = get_radix_u128(array_u8.span());
        assert(*u128_radix_array[0] == given.low, 'limb_0 != low');
        assert(*u128_radix_array[1] == given.high, 'limb_1 != high');
        given.print();
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
}