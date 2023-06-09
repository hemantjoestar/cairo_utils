use array::SpanTrait;
use array::ArrayTrait;
use option::OptionTrait;

use utils::math_funcs::pow_2;

trait PackInto<T, U> {
    fn pack_into(self: @Array<T>, hint: usize) -> Option<U>;
}
// impl U32ArrayPackIntoU256 of PackInto<u32, u256> {
impl ArrayPackInto<
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
    use array::ArrayTrait;
    use option::OptionTrait;
    use debug::PrintTrait;
    use super::PackInto;
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
        let precomputed_hash: u256 = // 0xfd187671a1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
        0xa1d5f861b976693a967019778bb2aaac30a36b419311ab63c741e9c9;
        assert(hash == precomputed_hash, 'Hash starknet Match fail');
    }
}
