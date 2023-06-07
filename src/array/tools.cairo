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
fn move_into_wide<
    T,
    U,
    impl TCopy: Copy<T>,
    impl TDrop: Drop<T>,
    impl UCopy: Copy<U>,
    impl UDrop: Drop<U>,
    impl TIntoU: Into<T, U>
>(
    mut in: Array<T>, ref out: Array<U>
) {
    loop {
        if in.is_empty() {
            break ();
        }
        out.append(TIntoU::into(in.pop_front().unwrap()));
    };
}
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
#[panic_with('MOVE_NARROW_ERROR', move_into_narrow)]
fn narrow_move<
    T,
    U,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
    impl UDrop: Drop<U>,
    impl TTryIntoU: TryInto<T, U>,
>(
    mut in: Array<T>, ref out: Array<U>
) -> Option<()> {
    let mut return_none = false;
    loop {
        if in.is_empty() {
            break ();
        }
        match TTryIntoU::try_into(in.pop_front().unwrap()) {
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
#[cfg(test)]
mod tests {
    use super::{SpanPrintImpl, copy_into_narrow, move_into_narrow, copy_into_wide, move_into_wide};
    use array::ArrayTrait;
    use array::SpanTrait;
    use debug::PrintTrait;

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
    #[should_panic(expected: ('MOVE_NARROW_ERROR', ))]
    fn tests_move_error() {
        let mut u16array = Default::<Array<u16>>::default();
        u16array.append(1_u16);
        u16array.append(256_u16);
        let mut u8array = Default::<Array<u8>>::default();
        move_into_narrow(u16array, ref u8array);
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
    #[test]
    #[available_gas(1000000)]
    fn tests_move() {
        let mut u16array = Default::default();
        u16array.append(1_u16);
        u16array.append(1_u16);
        let mut u8array = Default::<Array<u8>>::default();
        move_into_narrow(u16array, ref u8array);
        // move_into_narrow(u16array, ref u8array); //Move Error as expected
        let mut u32array = Default::default();
        u32array.append(255_u32);
        u32array.append(255_u32);
        move_into_narrow(u32array, ref u8array);
        // move_into_narrow(u32array, ref u8array); //Move Error as expected
        assert(u8array.len() == 4_usize, 'size error');
    }
// #[test]
// #[should_panic]
// #[available_gas(1000000)]
// fn test_move_panic() {
//     let mut u16array = Default::default();
//     u16array.append(1_u16);
//     u16array.append(256_u16);
//     let u8_array: Array<u8> = u16array.clone().move_into_narrow().unwrap();
// }
// #[test]
// #[ignore]
// #[available_gas(1000000)]
// #[should_panic(expected: ('Copy Error', ))]
// // #[should_panic]
// fn three() {
//     let mut u16array = Default::default();
//     u16array.append(1_u16);
//     u16array.append(256_u16);
//     let mut u32array = Default::<Array<u32>>::default();
//     move_into_wide(u16array, u32array);
// // copy_array_func::<u16, u8>(u16array,ref u8array);
// // copy_array_func::<u16, u32>(u16array, ref u8array);
// // panic_with_test::<u16, u8>(u16array); // Moved error as expected
// // panic_with_test_1::<u16, u8>(u16array); // Moved error as expected
// }
}

