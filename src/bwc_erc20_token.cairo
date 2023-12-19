use starknet::ContractAddress;
#[starknet::interface]
trait IERC20<TContractState> {
    fn get_name(self: @TContractState) -> felt252;
    fn get_symbol(self: @TContractState) -> felt252;
    fn get_decimals(self: @TContractState) -> u8;
    fn get_total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256);
    fn increase_allowance(ref self: TContractState, spender: ContractAddress, added_value: u256);
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    );
}

#[starknet::contract]
mod BWCERC20Token {
    // importing necessary libraries
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::contract_address_const; //similar to address(0) in Solidity
    use core::zeroable::Zeroable;
    use super::IERC20;

    //Stroge Variables
    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        totalSupply: u256,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
        balances: LegacyMap::<ContractAddress, u256>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        transfer: Transfer,
        approval: Approval
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        sender: ContractAddress,
        reciever: ContractAddress,
        value: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        value: u256
    }

    // contruct value to insert important perequsite values 
    #[constructor]
    fn constructor(
        ref self: ContractState,
        _owner: ContractAddress,
        _name: felt252,
        _symbol: felt252,
        _decimals: u8
    ) {
        self.name.write(_name);
        self.symbol.write(_symbol);
        self.decimals.write(_decimals);
    }

    // errors
    mod Errors {
        const ZERO_ADDRESS_ERROR: felt252 = 'This address is not allowed';
        const ZERO_VALUE: felt252 = 'this value is below minimum';
        const INSUFFICIENT_BALANCE: felt252 = 'insufficient balance';
        const ONLY_OWNER_ERROR: felt252 = 'caller not owner';
    }

    // fn to get total supply
    #[external(v0)]
    fn get_total_supply(self: @ContractState) -> u256 {
        self.totalSupply.read()
    }

    // fn to get balance of any user using address as key
    #[external(v0)]
    fn balanceOf(self: @ContractState, user_bal: ContractAddress) -> u256 {
        self.balances.read(user_bal)
    }

    // fn to transfer funds
    #[external(v0)]
    fn transfer(ref self: ContractState, _to: ContractAddress, _amount: u256) {
        let caller = get_caller_address();
        let caller_balance = self.balances.read(caller);
        let recievers_balance = self.balances.read(_to);

        // asserting amount is greatthan zero
        assert(_amount > 0, Errors::ZERO_VALUE);
        // asserting if caller_balance greater than amount to be sent
        assert(caller_balance > _amount, Errors::INSUFFICIENT_BALANCE);
        // asserting caller is not address zero
        assert(!caller.is_zero(), Errors::ZERO_ADDRESS_ERROR);

        // deduct amount from caller
        self.balances.write(caller, caller_balance - _amount);
        // adding amount to reciever
        self.balances.write(_to, recievers_balance + _amount);

        // emmit success event
        self.emit(Transfer { sender: caller, reciever: _to, value: _amount });
    }

    //  fn transfer from 
    #[external(v0)]
    fn transferFrom(
        ref self: ContractState, to: ContractAddress, from: ContractAddress, amount: u256
    ) {
        let caller = get_caller_address();
        let sender_balance = self.balances.read(from);
        let recievers_balance = self.balances.read(to);

        // asserting amount is greatthan zero
        assert(amount > 0, Errors::ZERO_VALUE);
        // asserting if caller_balance greater than amount to be sent
        assert(sender_balance > amount, Errors::INSUFFICIENT_BALANCE);
        // asserting caller is not address zero
        assert(!caller.is_zero(), Errors::ZERO_ADDRESS_ERROR);

        self.balances.write(from, sender_balance - amount);
        self.balances.write(to, recievers_balance + amount);

        // emmit success event
        self.emit(Transfer { sender: from, reciever: to, value: amount });
    }
}
