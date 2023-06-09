use array::SpanTrait;
use array::ArrayTrait;
use option::OptionTrait;
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
    use array::SpanTrait;
    use array::ArrayTrait;
    use option::OptionTrait;
    use super::{move_into_wide, move_into_narrow};
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
}
