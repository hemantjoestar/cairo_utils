use array::SpanTrait;
use array::ArrayTrait;
use option::OptionTrait;
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
#[cfg(test)]
mod tests {
    use array::SpanTrait;
    use array::ArrayTrait;
    use option::OptionTrait;
    use super::{copy_into_narrow, copy_into_wide};
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
}
