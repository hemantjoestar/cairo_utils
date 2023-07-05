use array::ArrayTrait;
use array::SpanTrait;
use serde::Serde;
use option::OptionTrait;
// use traits::TryInto;
use debug::PrintTrait;
// use traits::BitOr;

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

impl TBitNot<T, impl TBounded: integer::BoundedInt<T>, impl TSub: Sub<T>> of BitNot<T> {
    fn bitnot(a: T) -> T {
        TSub::sub(TBounded::max(), a)
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
