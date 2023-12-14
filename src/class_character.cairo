#[starknet::contract]
mod ClassCharacter {
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        name: felt252,
        w_address: ContractAddress,
        age: u8,
        is_active: bool,
        has_reward: bool,
        reward_balance: u256,
        is_owing: bool,
    }

    #[external(v0)]
    fn set_class_character(
        ref self: ContractState,
        _name: felt252,
        _w_address: ContractAddress,
        _age: u8,
        _is_active: bool,
        _has_reward: bool,
        _reward_balance: u256,
        _is_owing: bool
    ) {
        self.name.write(_name);
        self.w_address.write(_w_address);
        self.age.write(_age);
        self.is_active.write(_is_active);
        self.has_reward.write(_has_reward);
        self.reward_balance.write(_reward_balance);
        self.is_owing.write(_is_owing);
    }

    #[external(v0)]
    fn get_name(self: @ContractState) -> felt252 {
        self.name.read()
    }

    #[external(v0)]
    fn get_w_address(self: @ContractState) -> ContractAddress {
        self.w_address.read()
    }

    #[external(v0)]
    fn get_age(self: @ContractState) -> u8 {
        self.age.read()
    }

    #[external(v0)]
    fn get_is_active(self: @ContractState) -> bool {
        self.is_active.read()
    }

    #[external(v0)]
    fn get_has_reward(self: @ContractState) -> bool {
        self.has_reward.read()
    }

    #[external(v0)]
    fn get_reward_balance(self: @ContractState) -> u256 {
        self.reward_balance.read()
    }

    #[external(v0)]
    fn get_is_owing(self: @ContractState) -> bool {
        self.is_owing.read()
    }
}
