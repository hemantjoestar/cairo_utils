use array::{SpanTrait, ArrayTrait};
use option::OptionTrait;
use result::ResultTrait;
use clone::Clone;
use cairo_utils::array_ops::{reverse_self, move_into_wide, move_into_narrow, span_pack};
use integer::u512;
use debug::PrintTrait;

fn sha_512(mut bytes: Span<u128>) -> Result<u512, felt252> {
    // 1024 bits or 16 * 64 bit chunks for each iteration
    if (bytes.len() % 16_usize != 0) {
        return Result::Err('Input_length_!=16');
    }
    // Span
    let round_constants = load_round_constants();
    // Array
    let mut hash_values = load_hash_constants();
    // 1024 bits or 16 * 64 bit chunks for each iteration
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
            if message_loop_index == 80_usize {
                break ();
            }
            let s_0 = (*joined_bytes[message_loop_index - 15_usize]).rr_1()
                ^ (*(joined_bytes[message_loop_index - 15_usize])).rr_8()
                ^ (*(joined_bytes[message_loop_index - 15_usize])).shr_7();
            let s_1 = (*(joined_bytes[message_loop_index - 2_usize])).rr_19()
                ^ (*(joined_bytes[message_loop_index - 2_usize])).rr_61()
                ^ (*(joined_bytes[message_loop_index - 2_usize])).shr_6();
            joined_bytes
                .append(
                    (*(joined_bytes[message_loop_index - 16_usize]))
                        .modulo_2pow64_add(
                            s_0
                                .modulo_2pow64_add(
                                    (*(joined_bytes[message_loop_index - 7_usize]))
                                        .modulo_2pow64_add(s_1)
                                )
                        )
                );
            message_loop_index = message_loop_index + 1;
        };

        let mut working_hash = hash_values.clone();
        let mut compression_loop_index = 0_usize;
        loop {
            if compression_loop_index == 80_usize {
                break ();
            }
            let S_1 = (*(working_hash[3])).rr_14()
                ^ (*(working_hash[3])).rr_18()
                ^ (*(working_hash[3])).rr_41();
            let choice = (*working_hash[3] & *working_hash[2])
                ^ ((~(*working_hash[3])) & *working_hash[1]);
            let temp_1 = ((*working_hash[0]))
                .modulo_2pow64_add(
                    S_1
                        .modulo_2pow64_add(
                            choice
                                .modulo_2pow64_add(
                                    (*round_constants[compression_loop_index])
                                        .modulo_2pow64_add(*joined_bytes[compression_loop_index])
                                ),
                        )
                );

            let S_0 = (*(working_hash[7])).rr_28()
                ^ (*(working_hash[7])).rr_34()
                ^ (*(working_hash[7])).rr_39();
            let majority = (*working_hash[7] & *working_hash[6])
                ^ (*working_hash[7] & *working_hash[5])
                ^ (*working_hash[6] & *working_hash[5]);
            let temp_2 = S_0.modulo_2pow64_add(majority);

            working_hash.pop_front();
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append((*working_hash[0]).modulo_2pow64_add(temp_1));
            working_hash.pop_front();
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(working_hash.pop_front().unwrap());
            working_hash.append(temp_1.modulo_2pow64_add(temp_2));

            compression_loop_index = compression_loop_index + 1;
        };
        loop {
            if working_hash.is_empty() {
                break ();
            }

            hash_values
                .append(
                    ((hash_values.pop_front().unwrap())
                        .modulo_2pow64_add(working_hash.pop_front().unwrap()))
                );
        };
    };

    reverse_self::<u128>(ref hash_values);
    let mut u64_array = Default::<Array<u64>>::default();
    // u128 -> u64
    move_into_narrow(hash_values, ref u64_array);
    // pack 8 u64s into 4 u128s into u512 limbs
    let tmp_span = u64_array.span();
    let out = u512 {
        limb0: span_pack(tmp_span.slice(6, 2)).unwrap(),
        limb1: span_pack(tmp_span.slice(4, 2)).unwrap(),
        limb2: span_pack(tmp_span.slice(2, 2)).unwrap(),
        limb3: span_pack(tmp_span.slice(0, 2)).unwrap(),
    };
    Result::Ok(out)
}

impl U128Bit64Operations of SHA256BitOperations<u128> {
    fn modulo_2pow64_add(self: u128, other: u128) -> u128 {
        (self + other) & 0xFFFFFFFFFFFFFFFF
    }
    fn shr_6(self: u128) -> u128 {
        self / 0x40
    }
    fn shr_7(self: u128) -> u128 {
        self / 0x80
    }
    fn rr_1(self: u128) -> u128 {
        (self & 0xFFFFFFFFFFFFFFFE_u128) / 0x2_u128 | (self & 0x1_u128) * 0x8000000000000000_u128
    }
    fn rr_8(self: u128) -> u128 {
        (self & 0xFFFFFFFFFFFFFF00_u128) / 0x100_u128 | (self & 0xFF_u128) * 0x100000000000000_u128
    }
    fn rr_14(self: u128) -> u128 {
        (self & 0xFFFFFFFFFFFFC000_u128) / 0x4000_u128 | (self & 0x3FFF_u128) * 0x4000000000000_u128
    }
    fn rr_18(self: u128) -> u128 {
        (self & 0xFFFFFFFFFFFC0000_u128)
            / 0x40000_u128 | (self & 0x3FFFF_u128)
            * 0x400000000000_u128
    }
    fn rr_19(self: u128) -> u128 {
        (self & 0xFFFFFFFFFFF80000_u128)
            / 0x80000_u128 | (self & 0x7FFFF_u128)
            * 0x200000000000_u128
    }
    fn rr_28(self: u128) -> u128 {
        (self & 0xFFFFFFFFF0000000_u128)
            / 0x10000000_u128 | (self & 0xFFFFFFF_u128)
            * 0x1000000000_u128
    }
    fn rr_34(self: u128) -> u128 {
        (self & 0xFFFFFFFC00000000_u128)
            / 0x400000000_u128 | (self & 0x3FFFFFFFF_u128)
            * 0x40000000_u128
    }
    fn rr_39(self: u128) -> u128 {
        (self & 0xFFFFFF8000000000_u128)
            / 0x8000000000_u128 | (self & 0x7FFFFFFFFF_u128)
            * 0x2000000_u128
    }
    fn rr_41(self: u128) -> u128 {
        (self & 0xFFFFFE0000000000_u128)
            / 0x20000000000_u128 | (self & 0x1FFFFFFFFFF_u128)
            * 0x800000_u128
    }
    fn rr_61(self: u128) -> u128 {
        (self & 0xE000000000000000_u128)
            / 0x2000000000000000_u128 | (self & 0x1FFFFFFFFFFFFFFF_u128)
            * 0x8_u128
    }
}

trait SHA256BitOperations<T> {
    fn shr_6(self: T) -> T;
    fn shr_7(self: T) -> T;
    fn rr_1(self: T) -> T;
    fn rr_8(self: T) -> T;
    fn rr_14(self: T) -> T;
    fn rr_18(self: T) -> T;
    fn rr_19(self: T) -> T;
    fn rr_28(self: T) -> T;
    fn rr_34(self: T) -> T;
    fn rr_39(self: T) -> T;
    fn rr_41(self: T) -> T;
    fn rr_61(self: T) -> T;
    fn modulo_2pow64_add(self: T, other: T) -> T;
}

fn load_hash_constants() -> Array<u128> {
    let mut hash_values_array: Array::<u128> = Default::default();
    hash_values_array.append(0x5be0cd19137e2179);
    hash_values_array.append(0x1f83d9abfb41bd6b);
    hash_values_array.append(0x9b05688c2b3e6c1f);
    hash_values_array.append(0x510e527fade682d1);
    hash_values_array.append(0xa54ff53a5f1d36f1);
    hash_values_array.append(0x3c6ef372fe94f82b);
    hash_values_array.append(0xbb67ae8584caa73b);
    hash_values_array.append(0x6a09e667f3bcc908);
    hash_values_array
}

fn load_round_constants() -> Span<u128> {
    let mut round_constants_array: Array::<u128> = Default::default();
    round_constants_array.append(0x428a2f98d728ae22);
    round_constants_array.append(0x7137449123ef65cd);
    round_constants_array.append(0xb5c0fbcfec4d3b2f);
    round_constants_array.append(0xe9b5dba58189dbbc);
    round_constants_array.append(0x3956c25bf348b538);
    round_constants_array.append(0x59f111f1b605d019);
    round_constants_array.append(0x923f82a4af194f9b);
    round_constants_array.append(0xab1c5ed5da6d8118);
    round_constants_array.append(0xd807aa98a3030242);
    round_constants_array.append(0x12835b0145706fbe);
    round_constants_array.append(0x243185be4ee4b28c);
    round_constants_array.append(0x550c7dc3d5ffb4e2);
    round_constants_array.append(0x72be5d74f27b896f);
    round_constants_array.append(0x80deb1fe3b1696b1);
    round_constants_array.append(0x9bdc06a725c71235);
    round_constants_array.append(0xc19bf174cf692694);
    round_constants_array.append(0xe49b69c19ef14ad2);
    round_constants_array.append(0xefbe4786384f25e3);
    round_constants_array.append(0xfc19dc68b8cd5b5);
    round_constants_array.append(0x240ca1cc77ac9c65);
    round_constants_array.append(0x2de92c6f592b0275);
    round_constants_array.append(0x4a7484aa6ea6e483);
    round_constants_array.append(0x5cb0a9dcbd41fbd4);
    round_constants_array.append(0x76f988da831153b5);
    round_constants_array.append(0x983e5152ee66dfab);
    round_constants_array.append(0xa831c66d2db43210);
    round_constants_array.append(0xb00327c898fb213f);
    round_constants_array.append(0xbf597fc7beef0ee4);
    round_constants_array.append(0xc6e00bf33da88fc2);
    round_constants_array.append(0xd5a79147930aa725);
    round_constants_array.append(0x6ca6351e003826f);
    round_constants_array.append(0x142929670a0e6e70);
    round_constants_array.append(0x27b70a8546d22ffc);
    round_constants_array.append(0x2e1b21385c26c926);
    round_constants_array.append(0x4d2c6dfc5ac42aed);
    round_constants_array.append(0x53380d139d95b3df);
    round_constants_array.append(0x650a73548baf63de);
    round_constants_array.append(0x766a0abb3c77b2a8);
    round_constants_array.append(0x81c2c92e47edaee6);
    round_constants_array.append(0x92722c851482353b);
    round_constants_array.append(0xa2bfe8a14cf10364);
    round_constants_array.append(0xa81a664bbc423001);
    round_constants_array.append(0xc24b8b70d0f89791);
    round_constants_array.append(0xc76c51a30654be30);
    round_constants_array.append(0xd192e819d6ef5218);
    round_constants_array.append(0xd69906245565a910);
    round_constants_array.append(0xf40e35855771202a);
    round_constants_array.append(0x106aa07032bbd1b8);
    round_constants_array.append(0x19a4c116b8d2d0c8);
    round_constants_array.append(0x1e376c085141ab53);
    round_constants_array.append(0x2748774cdf8eeb99);
    round_constants_array.append(0x34b0bcb5e19b48a8);
    round_constants_array.append(0x391c0cb3c5c95a63);
    round_constants_array.append(0x4ed8aa4ae3418acb);
    round_constants_array.append(0x5b9cca4f7763e373);
    round_constants_array.append(0x682e6ff3d6b2b8a3);
    round_constants_array.append(0x748f82ee5defb2fc);
    round_constants_array.append(0x78a5636f43172f60);
    round_constants_array.append(0x84c87814a1f0ab72);
    round_constants_array.append(0x8cc702081a6439ec);
    round_constants_array.append(0x90befffa23631e28);
    round_constants_array.append(0xa4506cebde82bde9);
    round_constants_array.append(0xbef9a3f7b2c67915);
    round_constants_array.append(0xc67178f2e372532b);
    round_constants_array.append(0xca273eceea26619c);
    round_constants_array.append(0xd186b8c721c0c207);
    round_constants_array.append(0xeada7dd6cde0eb1e);
    round_constants_array.append(0xf57d4f7fee6ed178);
    round_constants_array.append(0x6f067aa72176fba);
    round_constants_array.append(0xa637dc5a2c898a6);
    round_constants_array.append(0x113f9804bef90dae);
    round_constants_array.append(0x1b710b35131c471b);
    round_constants_array.append(0x28db77f523047d84);
    round_constants_array.append(0x32caab7b40c72493);
    round_constants_array.append(0x3c9ebe0a15c9bebc);
    round_constants_array.append(0x431d67c49c100d4c);
    round_constants_array.append(0x4cc5d4becb3e42b6);
    round_constants_array.append(0x597f299cfc657e2a);
    round_constants_array.append(0x5fcb6fab3ad6faec);
    round_constants_array.append(0x6c44198c4a475817);
    round_constants_array.span()
}
