fn sum(a: felt252, b: felt252) -> felt252 {
    a + b
}

fn prod(a: felt252, b: felt252) -> felt252 {
    a * b
}

// Command to modify seed or runs: snforge --fuzzer-runs 1234 --fuzzer-seed 1111

#[test]
fn test_fuzz_sum(x: felt252, y: felt252) {
    assert (sum(x,y) == (x + y), 'Summation Failed');
}

#[test]
fn test_fuzz_prod(x: felt252, y: felt252) {
    assert (prod(x,y) == (x * y), 'Multiplication Failed');
}