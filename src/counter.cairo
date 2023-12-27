#[starknet::interface]
trait ICounter<T> {
    fn increase_count(ref self: T, amount: u256) -> bool;
    fn decrease_count(ref self: T, amount: u256) -> bool;
    fn get_count(self: @T) -> u256;
}

mod Errors {
    const ZERO_AMT: felt252 = '0_AMT: detected';
    const INVALID_AMOUNT: felt252 = 'INVALID_AMT: detected';
}

#[starknet::contract]
mod Counter {
    use super::{ICounter, Errors};
    #[storage]
    struct Storage {
        count: u256
    }


    #[external(v0)]
    impl ICounterImpl of ICounter<ContractState> {
        fn increase_count(ref self: ContractState, amount: u256) -> bool {
            assert(amount != 0, Errors::ZERO_AMT);
            let count = self.count.read();
            self.count.write(count + amount);
            true
        }

        fn decrease_count(ref self: ContractState, amount: u256) -> bool {
            assert(amount != 0, Errors::ZERO_AMT);
            let count = self.count.read();
            assert(amount <= count, Errors::INVALID_AMOUNT);
            self.count.write(count - amount);
            true
        }
        fn get_count(self: @ContractState) -> u256 {
            self.count.read()
        }
    }
}
