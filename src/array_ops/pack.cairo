use array::SpanTrait;
use array::ArrayTrait;
use option::OptionTrait;
use traits::BitOr;

use cairo_utils::math_funcs::pow_2;

trait MaxPack<T, U> {
    fn max_pack_into() -> usize;
}
impl U32MacPackU256 of MaxPack<u32, u256> {
    fn max_pack_into() -> usize {
        8
    }
}
impl U64MacPackFelt252 of MaxPack<u64, felt252> {
    fn max_pack_into() -> usize {
        3
    }
}
impl U64MacPackU128 of MaxPack<u64, u128> {
    fn max_pack_into() -> usize {
        2
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
    impl TTryIntoU8: TryInto<u32, u8>
>(
    mut in: Span<T>
) -> Option<U> {
    // short circuit
    if in.len() == 1_usize {
        return Option::Some(TIntoU::into(*in.at(1)));
    }
    if in.len() <= TMaxPackIntoU::max_pack_into() {
        let mut output = Default::<U>::default();
        loop {
            if in.is_empty() {
                break ();
            }
            output = output
                | (TIntoU::into(*(in.pop_front().unwrap()))
                    * pow_2::<U>(TTryIntoU8::try_into(in.len()).unwrap() * 32).unwrap());
        };
        return Option::Some(output);
    }
    Option::None(())
}
#[cfg(test)]
mod tests {
    use array::SpanTrait;
    use array::ArrayTrait;
    use option::OptionTrait;
    use debug::PrintTrait;
    use super::span_pack;
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
        let hash: u256 = span_pack(array_u32.span()).unwrap();
        // let hash: u256 = U32ArrayPackIntoU256::<u32, u256>::pack_into(@array_u32, 8).unwrap();
        let precomputed_hash: u256 =
            // 0xfd187671a1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
            0xa1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
        assert(hash == precomputed_hash, 'Hash starknet Match fail');
    // let hash: u64 = span_pack(array_u32.span()).unwrap();
    }
}
