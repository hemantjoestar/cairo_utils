use array::ArrayTrait;
use array::SpanTrait;
use serde::Serde;
use option::OptionTrait;
use traits::TryInto;
use debug::PrintTrait;


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
