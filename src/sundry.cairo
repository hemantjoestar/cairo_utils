use array::ArrayTrait;
use array::SpanTrait;
use serde::Serde;
use option::OptionTrait;
use traits::TryInto;
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

impl TSerdeImpl<
    T,
    impl TCopy: Copy<T>,
    impl TIntoFelt252: Into<T, felt252>,
    impl Felt252TryIntoT: TryInto<felt252, T>
> of Serde<T> {
    fn serialize(self: @T, ref output: Array<felt252>) {
        TIntoFelt252::into(*self).serialize(ref output);
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<T> {
        Option::Some(Felt252TryIntoT::try_into(*serialized.pop_front()?)?)
    }
}

impl TBitAnd<
    T, impl TIntoU128: Into<T, u128>, impl U128TryIntoT: TryInto<u128, T>, impl TDrop: Drop<T>, 
> of BitAnd<T> {
    #[inline(always)]
    fn bitand(lhs: T, rhs: T) -> T {
        let lhs_u128 = TIntoU128::into(lhs);
        let rhs_u128 = TIntoU128::into(rhs);
        U128TryIntoT::try_into(lhs_u128 & rhs_u128).unwrap()
    }
}

impl TBitXor<
    T, impl TIntoU128: Into<T, u128>, impl U128TryIntoT: TryInto<u128, T>, impl TDrop: Drop<T>, 
> of BitXor<T> {
    #[inline(always)]
    fn bitxor(lhs: T, rhs: T) -> T {
        let lhs_u128 = TIntoU128::into(lhs);
        let rhs_u128 = TIntoU128::into(rhs);
        U128TryIntoT::try_into(lhs_u128 ^ rhs_u128).unwrap()
    }
}

fn serialized_element<T, impl TSerde: serde::Serde<T>, impl TDestruct: Destruct<T>>(
    value: T
) -> Span<felt252> {
    let mut arr = Default::default();
    value.serialize(ref arr);
    arr.span()
}

fn deserialized_element<T, impl TSerde: serde::Serde<T>>(
    ref data: Span::<felt252>, errmsg: felt252
) -> T {
    serde::Serde::deserialize(ref data).expect(errmsg)
}
