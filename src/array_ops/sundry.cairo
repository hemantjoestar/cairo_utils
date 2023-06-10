use debug::PrintTrait;
use array::SpanTrait;
use option::OptionTrait;

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
