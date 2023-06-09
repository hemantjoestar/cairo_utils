const ZERO: u256 = 0_u256;
const ONE: u256 = 1_u256;

fn egcd_prime(prime: u256, other: u256, t_1: u256, t_2: u256, iter: u256) -> (u256, u256) {
    let quotient = prime / other;
    let rem = prime % other;
    if rem == ZERO {
        (t_2, iter)
    } else {
        let t = t_1 + quotient * t_2;
        let iter = iter + 1;
        egcd_prime(other, rem, t_2, t, iter)
    }
}
fn mod_inv(prime: u256, other: u256) -> u256 {
    // Initialize
    // assert prime > other. egcd doesnt account for that
    let (psuedo_inverse, iter) = egcd_prime(prime, other, 0, 1, 0);
    if iter % 2_u256 != 0 {
        prime - psuedo_inverse
    } else {
        psuedo_inverse
    }
}

#[cfg(test)]
mod tests {
    use super::mod_inv;
    const R1_P: u256 = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    const R1_PMINUS2: u256 = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFD;
    const R1_A: u256 = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
    const R1_B: u256 = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
    const R1_G: u256 = 0x036B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C2;


    #[test]
    #[available_gas(100000000)]
    fn test_egcd_recursive() {
        assert(mod_inv(26, 11) == 19, 'should be 19');
        assert(mod_inv(2017, 42) == 1969, 'should be 19');
        let mut tmp = 12345678909876543211234567890987654321_u256;
        let mut result =
            68065946369199528823380472835907547546666963150606856663506223408030294186972_u256;
        let mut inv = mod_inv(R1_P, tmp);
        assert(inv == result, 'random');
        inv = mod_inv(R1_P, R1_B);
        result = 77625186191858790278236044393286048037829153579542035652854769692995702872485_u256;
        assert(inv == result, 'R1_B');
        inv = mod_inv(R1_P, R1_A);
        result = 38597363070118749587565815649802524510028714471763438065177877102955699284650_u256;
        assert(inv == result, 'R1_A');
        inv = mod_inv(R1_P, R1_G);
        result = 40578452312509121938714706746502911312959995705360876345905075855717943636361_u256;
        assert(inv == result, 'R1_G');
        inv = mod_inv(R1_P, R1_PMINUS2);
        result = 57896044605178124381348723474703786765043071707645157097766815654433548926975_u256;
        assert(inv == result, 'R1_PMINUS2');
    }
    #[test]
    #[ignore]
    #[should_panic]
    #[available_gas(1000000)]
    fn wrong() {
        mod_inv(R1_P, R1_P);
    }
}
