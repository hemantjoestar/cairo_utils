use array::{SpanTrait, ArrayTrait};
use option::OptionTrait;
use result::ResultTrait;
use clone::Clone;
use cairo_utils::array_ops::{reverse_self, move_into_narrow, span_pack};

fn sha_256(mut bytes: Span<u128>) -> Result<u256, felt252> {
    // 512 bits or 16 * 32 bit chunks for each iteration
    if (bytes.len() % 16_usize != 0) {
        return Result::Err('Input_length_!=16');
    }
    // Using Span resolved issue. check TODO in compression section
    // Span
    let round_constants = load_round_constants();
    // Array
    let mut hash_values = load_hash_constants();

    // 512 bits or 16 * 32 bit chunks for each iteration
    loop {
        // input completed
        if bytes.is_empty() {
            break ();
        }
        let mut joined_bytes = Default::<Array<u128>>::default();
        loop {
            if joined_bytes.len() == 16_usize {
                break ();
            }
            joined_bytes.append(*bytes.pop_front().unwrap());
        };

        // Message Loop
        let mut message_loop_index: usize = 16;
        loop {
            if message_loop_index == 64_usize {
                break ();
            }
            let s_0 = (*joined_bytes[message_loop_index - 15_usize]).rr_7()
                ^ (*(joined_bytes[message_loop_index - 15_usize])).rr_18()
                ^ (*(joined_bytes[message_loop_index - 15_usize])).shr_3();
            let s_1 = (*(joined_bytes[message_loop_index - 2_usize])).rr_17()
                ^ (*(joined_bytes[message_loop_index - 2_usize])).rr_19()
                ^ (*(joined_bytes[message_loop_index - 2_usize])).shr_10();
            joined_bytes
                .append(
                    (*(joined_bytes[message_loop_index - 16_usize]))
                        .modulo_2pow32_add(
                            s_0
                                .modulo_2pow32_add(
                                    (*(joined_bytes[message_loop_index - 7_usize]))
                                        .modulo_2pow32_add(s_1)
                                )
                        )
                );
            message_loop_index = message_loop_index + 1;
        };

        let mut working_hash = hash_values.clone();
        let mut compression_loop_index = 0_usize;
        // TODO: Used Span. need to measure if better against Array. Also span resolved issue below
        // TODO: Not needed to be loaded repeatedly. but loop moved problem. unroll didnt work
        // let round_constants = load_round_constants();
        loop {
            if compression_loop_index == 64_usize {
                break ();
            }
            let S_1 = (*(working_hash[3])).rr_6()
                ^ (*(working_hash[3])).rr_11()
                ^ (*(working_hash[3])).rr_25();
            let choice = (*working_hash[3] & *working_hash[2])
                ^ ((~(*working_hash[3])) & *working_hash[1]);
            let temp_1 = ((*working_hash[0]))
                .modulo_2pow32_add(
                    S_1
                        .modulo_2pow32_add(
                            choice
                                .modulo_2pow32_add(
                                    (*round_constants[compression_loop_index])
                                        .modulo_2pow32_add(*joined_bytes[compression_loop_index])
                                ),
                        )
                );

            let S_0 = (*(working_hash[7])).rr_2()
                ^ (*(working_hash[7])).rr_13()
                ^ (*(working_hash[7])).rr_22();
            let majority = (*working_hash[7] & *working_hash[6])
                ^ (*working_hash[7] & *working_hash[5])
                ^ (*working_hash[6] & *working_hash[5]);
            let temp_2 = S_0.modulo_2pow32_add(majority);

            working_hash.pop_front();
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append((*working_hash[0]).modulo_2pow32_add(temp_1));
            working_hash.pop_front();
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(temp_1.modulo_2pow32_add(temp_2));

            compression_loop_index = compression_loop_index + 1;
        };
        loop {
            if working_hash.is_empty() {
                break ();
            }

            hash_values
                .append(
                    ((hash_values.pop_front().unwrap())
                        .modulo_2pow32_add(working_hash.pop_front().unwrap()))
                );
        };
    };

    reverse_self::<u128>(ref hash_values);
    // Because actually u32 values inside else could spanpack direct
    let mut output = Default::<Array<u32>>::default();
    move_into_narrow(hash_values, ref output);
    Result::Ok(span_pack(output.span()).unwrap())
}

impl U128Bit32Operations of SHA256BitOperations<u128> {
    fn modulo_2pow32_add(self: u128, other: u128) -> u128 {
        (self + other) & 0xFFFFFFFF
    }
    fn shr_3(self: u128) -> u128 {
        self / 0x8
    }
    fn shr_10(self: u128) -> u128 {
        self / 0x400
    }
    fn rr_2(self: u128) -> u128 {
        (self & 0xFFFFFFFC) / 0x4 | (self & 0x3) * 0x40000000
    }
    fn rr_6(self: u128) -> u128 {
        (self & 0xFFFFFFC0) / 0x40 | (self & 0x3F) * 0x4000000
    }
    fn rr_7(self: u128) -> u128 {
        (self & 0xFFFFFF80) / 0x80 | (self & 0x7F) * 0x2000000
    }
    fn rr_11(self: u128) -> u128 {
        (self & 0xFFFFF800) / 0x800 | (self & 0x7FF) * 0x200000
    }
    fn rr_13(self: u128) -> u128 {
        (self & 0xFFFFE000) / 0x2000 | (self & 0x1FFF) * 0x80000
    }
    fn rr_17(self: u128) -> u128 {
        (self & 0xFFFE0000) / 0x20000 | (self & 0x1FFFF) * 0x8000
    }
    fn rr_18(self: u128) -> u128 {
        (self & 0xFFFC0000) / 0x40000 | (self & 0x3FFFF) * 0x4000
    }
    fn rr_19(self: u128) -> u128 {
        (self & 0xFFF80000) / 0x80000 | (self & 0x7FFFF) * 0x2000
    }
    fn rr_22(self: u128) -> u128 {
        (self & 0xFFC00000) / 0x400000 | (self & 0x3FFFFF) * 0x400
    }
    fn rr_25(self: u128) -> u128 {
        (self & 0xFE000000) / 0x2000000 | (self & 0x1FFFFFF) * 0x80
    }
}

trait SHA256BitOperations<T> {
    fn modulo_2pow32_add(self: T, other: T) -> T;
    fn rr_2(self: T) -> T;
    fn rr_6(self: T) -> T;
    fn rr_7(self: T) -> T;
    fn rr_11(self: T) -> T;
    fn rr_13(self: T) -> T;
    fn rr_17(self: T) -> T;
    fn rr_18(self: T) -> T;
    fn rr_19(self: T) -> T;
    fn rr_22(self: T) -> T;
    fn rr_25(self: T) -> T;
    fn shr_3(self: T) -> T;
    fn shr_10(self: T) -> T;
}

fn load_hash_constants() -> Array<u128> {
    let mut hash_values: Array::<u128> = Default::default();
    hash_values.append(0x5be0cd19);
    hash_values.append(0x1f83d9ab);
    hash_values.append(0x9b05688c);
    hash_values.append(0x510e527f);
    hash_values.append(0xa54ff53a);
    hash_values.append(0x3c6ef372);
    hash_values.append(0xbb67ae85);
    hash_values.append(0x6a09e667);
    hash_values
}

fn load_round_constants() -> Span<u128> {
    let mut round_constants_array: Array::<u128> = Default::default();
    round_constants_array.append(0x428a2f98);
    round_constants_array.append(0x71374491);
    round_constants_array.append(0xb5c0fbcf);
    round_constants_array.append(0xe9b5dba5);
    round_constants_array.append(0x3956c25b);
    round_constants_array.append(0x59f111f1);
    round_constants_array.append(0x923f82a4);
    round_constants_array.append(0xab1c5ed5);
    round_constants_array.append(0xd807aa98);
    round_constants_array.append(0x12835b01);
    round_constants_array.append(0x243185be);
    round_constants_array.append(0x550c7dc3);
    round_constants_array.append(0x72be5d74);
    round_constants_array.append(0x80deb1fe);
    round_constants_array.append(0x9bdc06a7);
    round_constants_array.append(0xc19bf174);
    round_constants_array.append(0xe49b69c1);
    round_constants_array.append(0xefbe4786);
    round_constants_array.append(0x0fc19dc6);
    round_constants_array.append(0x240ca1cc);
    round_constants_array.append(0x2de92c6f);
    round_constants_array.append(0x4a7484aa);
    round_constants_array.append(0x5cb0a9dc);
    round_constants_array.append(0x76f988da);
    round_constants_array.append(0x983e5152);
    round_constants_array.append(0xa831c66d);
    round_constants_array.append(0xb00327c8);
    round_constants_array.append(0xbf597fc7);
    round_constants_array.append(0xc6e00bf3);
    round_constants_array.append(0xd5a79147);
    round_constants_array.append(0x06ca6351);
    round_constants_array.append(0x14292967);
    round_constants_array.append(0x27b70a85);
    round_constants_array.append(0x2e1b2138);
    round_constants_array.append(0x4d2c6dfc);
    round_constants_array.append(0x53380d13);
    round_constants_array.append(0x650a7354);
    round_constants_array.append(0x766a0abb);
    round_constants_array.append(0x81c2c92e);
    round_constants_array.append(0x92722c85);
    round_constants_array.append(0xa2bfe8a1);
    round_constants_array.append(0xa81a664b);
    round_constants_array.append(0xc24b8b70);
    round_constants_array.append(0xc76c51a3);
    round_constants_array.append(0xd192e819);
    round_constants_array.append(0xd6990624);
    round_constants_array.append(0xf40e3585);
    round_constants_array.append(0x106aa070);
    round_constants_array.append(0x19a4c116);
    round_constants_array.append(0x1e376c08);
    round_constants_array.append(0x2748774c);
    round_constants_array.append(0x34b0bcb5);
    round_constants_array.append(0x391c0cb3);
    round_constants_array.append(0x4ed8aa4a);
    round_constants_array.append(0x5b9cca4f);
    round_constants_array.append(0x682e6ff3);
    round_constants_array.append(0x748f82ee);
    round_constants_array.append(0x78a5636f);
    round_constants_array.append(0x84c87814);
    round_constants_array.append(0x8cc70208);
    round_constants_array.append(0x90befffa);
    round_constants_array.append(0xa4506ceb);
    round_constants_array.append(0xbef9a3f7);
    round_constants_array.append(0xc67178f2);
    round_constants_array.span()
}
