use array::ArrayTrait;
use array::SpanTrait;
use option::OptionTrait;

fn reverse_array<T, impl TDrop: Drop<T>, impl TCopy: Copy<T>>(on: Span<T>) -> Array<T> {
    let mut reversed = Default::<Array<T>>::default();
    reverse_into(on, ref reversed);
    reversed
}

fn reverse_into<T, impl TDrop: Drop<T>, impl TCopy: Copy<T>>(mut on: Span<T>, ref into: Array<T>) {
    if on.len() == 0 {
        return;
    }
    loop {
        if on.is_empty() {
            break ();
        }
        into.append(*on.pop_back().unwrap());
    };
}

fn reverse_self<T, impl TDrop: Drop<T>, impl TCopy: Copy<T>>(ref on: Array<T>) {
    if on.len() == 1 || on.len() == 0 {
        return;
    }
    let original_length = on.len();
    let mut index: usize = on.len() - 2;
    loop {
        if index == 0_usize {
            on.append(*on[index]);
            break ();
        }
        on.append(*on[index]);
        index = index - 1_usize;
    };
    loop {
        if on.len() == original_length {
            break ();
        }
        on.pop_front();
    };
}


#[cfg(test)]
mod tests {
    use array::ArrayTrait;
    use super::{reverse_array, reverse_self};
    #[test]
    #[available_gas(1000000)]
    fn tests_reverse_self() {
        let mut arr = Default::default();
        arr.append(1_u256);
        arr.append(2_u256);
        arr.append(3_u256);
        arr.append(5_u256);
        arr.append(4_u256);
        reverse_self(ref arr);
        assert(*arr[0] == 4_u256, '1 element');
        assert(*arr[1] == 5_u256, '2 element');
        assert(*arr[2] == 3_u256, '3 element');
        assert(*arr[3] == 2_u256, '4 element');
        assert(*arr[4] == 1_u256, '5 element');
    }
    #[test]
    #[available_gas(1000000)]
    fn tests_reverse_new() {
        let mut arr = Default::default();
        arr.append(1_u256);
        arr.append(2_u256);
        arr.append(3_u256);
        arr.append(5_u256);
        arr.append(4_u256);
        let mut reversed_arr = reverse_array(arr.span());
        assert(*reversed_arr[0] == 4_u256, '1 element');
        assert(*reversed_arr[1] == 5_u256, '2 element');
        assert(*reversed_arr[2] == 3_u256, '3 element');
        assert(*reversed_arr[3] == 2_u256, '4 element');
        assert(*reversed_arr[4] == 1_u256, '5 element');
    }
    #[test]
    #[available_gas(1000000)]
    fn tests_zero_size_reverse() {
        let mut arr = Default::<Array<u32>>::default();
        let mut reversed_arr = reverse_array(arr.span());
        reverse_self(ref arr);
    }
    #[test]
    #[available_gas(1000000)]
    fn tests_one_size_reverse() {
        let mut arr = Default::<Array<u256>>::default();
        arr.append(5_u256);
        let mut reversed_arr = reverse_array(arr.span());
        // assert(*reversed_arr[0] == 5_u256, '1 element');
        reverse_self(ref arr);
        assert(*arr[0] == 5_u256, '1 element');
    }
}
