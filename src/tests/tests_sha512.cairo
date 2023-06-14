use option::OptionTrait;
use result::ResultTrait;
use array::ArrayTrait;
use debug::PrintTrait;
use cairo_utils::array_ops::span_pack;
use cairo_utils::sundry::SpanPrintImpl;
use cairo_utils::array_ops::{move_into_narrow, copy_into_wide};
use cairo_utils::hash::sha_512;
use integer::u512;
use serde::Serde;

// let test_str = b"starknet";
#[test]
#[available_gas(200000000)]
fn tests_less_than_1024_bits() {
    let mut input = Default::<Array<u64>>::default();
    input.append(0x737461726B6E6574);
    input.append(0x8000000000000000);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x40);
    let mut u128_array = Default::<Array<u128>>::default();
    copy_into_wide(input.span(), ref u128_array);
    let precomputed_hash = u512 {
        limb0: 0xEDABE62F9E5394175071FC67FE7FCC84,
        limb1: 0xD51C59F7EECF69F40DFA02C2F5298189,
        limb2: 0xFC258B6F0D92290B3B86B6FD5D8847BA,
        limb3: 0x1D9AC9FDE6731D226BD4A2BA6BA6EADC,
    };
    let hash = sha_512(u128_array.span()).unwrap();
    let mut tmp_1 = Default::default();
    hash.serialize(ref tmp_1);
    tmp_1.print();
    assert(sha_512(u128_array.span()).unwrap() == precomputed_hash, 'Hash starknet Match fail');
}
// let test_str = b"Cairo is the first Turing-complete language for creating provable programs for general computation.";
#[test]
#[available_gas(200000000)]
fn tests_less_than_1024_bits_again() {
    let mut input = Default::<Array<u64>>::default();
    input.append(0x436169726F206973);
    input.append(0x2074686520666972);
    input.append(0x737420547572696E);
    input.append(0x672D636F6D706C65);
    input.append(0x7465206C616E6775);
    input.append(0x61676520666F7220);
    input.append(0x6372656174696E67);
    input.append(0x2070726F7661626C);
    input.append(0x652070726F677261);
    input.append(0x6D7320666F722067);
    input.append(0x656E6572616C2063);
    input.append(0x6F6D707574617469);
    input.append(0x6F6E2E8000000000);
    input.append(0x0);
    input.append(0x0);
    input.append(0x318);
    let mut u128_array = Default::<Array<u128>>::default();
    copy_into_wide(input.span(), ref u128_array);
    let precomputed_hash = u512 {
        limb3: 0xE8E44D3B93EFA2BD0850AD65CEFCD48F,
        limb2: 0x51A38EA529C82B6AED338D4CD027C351,
        limb1: 0xEB33956F8C79DA09AA3E19D18DF5D802,
        limb0: 0x98DA7F977BADCAA9BDBF8B248B186A5B
    };
    let hash = sha_512(u128_array.span()).unwrap();
    let mut tmp_1 = Default::default();
    hash.serialize(ref tmp_1);
    tmp_1.print();
    assert(sha_512(u128_array.span()).unwrap() == precomputed_hash, 'Hash starknet Match fail');
}
// Cairo Wwhitepaper Abstract
#[test]
#[available_gas(600000000)]
fn tests_more_than_1024_bits() {
    let mut input = Default::<Array<u64>>::default();
    input.append(0x5765207072657365);
    input.append(0x6E7420436169726F);
    input.append(0x2C20612070726163);
    input.append(0x746963616C6C792D);
    input.append(0x656666696369656E);
    input.append(0x7420547572696E67);
    input.append(0x2D636F6D706C6574);
    input.append(0x6520535441524B2D);
    input.append(0x667269656E646C79);
    input.append(0xA20202020202020);
    input.append(0x2020202020435055);
    input.append(0x2061726368697465);
    input.append(0x63747572652E2057);
    input.append(0x6520646573637269);
    input.append(0x626520612073696E);
    input.append(0x676C652073657420);
    input.append(0x6F6620706F6C796E);
    input.append(0x6F6D69616C206571);
    input.append(0x756174696F6E7320);
    input.append(0x666F720A20202020);
    input.append(0x2020202020202020);
    input.append(0x7468652073746174);
    input.append(0x656D656E74207468);
    input.append(0x6174207468652065);
    input.append(0x7865637574696F6E);
    input.append(0x206F662061207072);
    input.append(0x6F6772616D206F6E);
    input.append(0x2074686973206172);
    input.append(0x6368697465637475);
    input.append(0x72652069730A2020);
    input.append(0x2020202020202020);
    input.append(0x202076616C69642E);
    input.append(0x20476976656E2061);
    input.append(0x2073746174656D65);
    input.append(0x6E74206F6E652077);
    input.append(0x697368657320746F);
    input.append(0x2070726F76652C20);
    input.append(0x436169726F20616C);
    input.append(0x6C6F777320777269);
    input.append(0x74696E6720610A20);
    input.append(0x2020202020202020);
    input.append(0x20202070726F6772);
    input.append(0x616D207468617420);
    input.append(0x6465736372696265);
    input.append(0x7320746861742073);
    input.append(0x746174656D656E74);
    input.append(0x2C20696E73746561);
    input.append(0x64206F6620777269);
    input.append(0x74696E6720612073);
    input.append(0x6574206F6620706F);
    input.append(0x6C796E6F6D69616C);
    input.append(0x206571756174696F);
    input.append(0x6E732E8000000000);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0x0);
    input.append(0xD18);
    let mut u128_array = Default::<Array<u128>>::default();
    copy_into_wide(input.span(), ref u128_array);
    let precomputed_hash = u512 {
        limb3: 0x8F831E96B523273508A442E409C4C81C,
        limb2: 0x525C59F3DA26C4E4A58E9437160B9788,
        limb1: 0xF4340836B589135156B9E0940955C977,
        limb0: 0x3B41EFA8F3985F2B0744D3D639D339B,
    };
    let hash = sha_512(u128_array.span()).unwrap();
    let mut tmp_1 = Default::default();
    hash.serialize(ref tmp_1);
    tmp_1.print();
    assert(sha_512(u128_array.span()).unwrap() == precomputed_hash, 'Hash CWP Match fail');
}
