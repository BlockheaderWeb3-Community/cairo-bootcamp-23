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
        total_supply: u256,
        balances: LegacyMap<ContractAddress, u256>,
        allowances: LegacyMap<
            (ContractAddress, ContractAddress), u256
        >, //similar to mapping(address => mapping(address => uint256))
    }
    //  Event
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Approval: Approval,
        Transfer: Transfer
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        value: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        value: u256,
    }

    // Note: The contract constructor is not part of the interface. Nor are internal functions part of the interface.

    // Constructor 
    #[constructor]
    fn constructor(ref self: ContractState, // _name: felt252,
     // _symbol: felt252,
    // _decimal: u8,
    // _initial_supply: u256,
    recipient: ContractAddress) {
        // The .is_zero() method here is used to determine whether the address type recipient is a 0 address, similar to recipient == address(0) in Solidity.
        assert(!recipient.is_zero(), 'transfer to zero address');
        self.name.write('BlockheaderToken');
        self.symbol.write('BHT');
        self.decimals.write(18);
        self.total_supply.write(1000000);
        self.balances.write(recipient, 1000000);

        self
            .emit(
                Transfer { //Here, `contract_address_const::<0>()` is similar to address(0) in Solidity
                    from: contract_address_const::<0>(), to: recipient, value: 1000000
                }
            );
    }

    #[external(v0)]
    impl IERC20Impl of IERC20<ContractState> {
        fn get_name(self: @ContractState) -> felt252 {
            self.name.read()
        }
        fn get_symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn get_decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }

        fn get_total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }


        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowances.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            self.transfer_helper(caller, recipient, amount);
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            let caller = get_caller_address();
            let my_allowance = self.allowances.read((sender, caller));
            assert(my_allowance > 0, 'You have no token approved');
            assert(amount <= my_allowance, 'Amount Not Allowed');
            // assert(my_allowance <= amount, 'Amount Not Allowed');
            self
                .spend_allowance(
                    sender, caller, amount
                ); //responsible for deduction of the amount allowed to spend
            self.transfer_helper(sender, recipient, amount);
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            self.approve_helper(caller, spender, amount);
        }

        fn increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) {
            let caller = get_caller_address();
            self
                .approve_helper(
                    caller, spender, self.allowances.read((caller, spender)) + added_value
                );
        }

        fn decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u256
        ) {
            let caller = get_caller_address();
            self
                .approve_helper(
                    caller, spender, self.allowances.read((caller, spender)) - subtracted_value
                );
        }
    }

    #[generate_trait]
    impl HelperImpl of HelperTrait {
        fn transfer_helper(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            let sender_balance = self.balance_of(sender);

            assert(!sender.is_zero(), 'transfer from 0');
            assert(!recipient.is_zero(), 'transfer to 0');
            assert(sender_balance >= amount, 'Insufficient fund');
            self.balances.write(sender, self.balances.read(sender) - amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            true;

            self.emit(Transfer { from: sender, to: recipient, value: amount, });
        }

        fn approve_helper(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!owner.is_zero(), 'approve from 0');
            assert(!spender.is_zero(), 'approve to 0');

            self.allowances.write((owner, spender), amount);

            self.emit(Approval { owner, spender, value: amount, })
        }

        fn spend_allowance(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            // First, read the amount authorized by owner to spender
            let current_allowance = self.allowances.read((owner, spender));

            // define a variable ONES_MASK of type u128
            let ONES_MASK = 0xfffffffffffffffffffffffffffffff_u128;

            // to determine whether the authorization is unlimited, 

            let is_unlimited_allowance = current_allowance.low == ONES_MASK
                && current_allowance
                    .high == ONES_MASK; //equivalent to type(uint256).max in Solidity.

            // This is also a way to save gas, because if the authorized amount is the maximum value of u256, theoretically, this amount cannot be spent.
            if !is_unlimited_allowance {
                self.approve_helper(owner, spender, current_allowance - amount);
            }
        }
    }
}


#[cfg(test)]
mod test {
    use core::serde::Serde;
    use super::{IERC20, BWCERC20Token, IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::ContractAddress;
    use starknet::contract_address::contract_address_const;
    use core::array::ArrayTrait;
    use snforge_std::{declare, ContractClassTrait, fs::{FileTrait, read_txt}};
    use snforge_std::{start_prank, stop_prank, CheatTarget};
    use snforge_std::PrintTrait;
    use core::traits::{Into, TryInto};

    // helper function
    fn deploy_contract() -> ContractAddress {
        let erc20_contract_class = declare('BWCERC20Token');
        let file = FileTrait::new('data/constructor_args.txt');
        let constructor_args = read_txt(@file);

        let contract_address = erc20_contract_class.deploy(@constructor_args).unwrap();
        contract_address
    }

    #[test]
    fn test_constructor() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        let name = dispatcher.get_name();
        assert(name == 'BlockheaderToken', 'name is not correct');
    }

    #[test]
    fn test_symbol_is_correct() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        let symbol = dispatcher.get_symbol();
        assert(symbol == 'BHT', 'symbol is not correct');
    }

    #[test]
    fn test_decimal_is_correct() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        let decimal = dispatcher.get_decimals();
        assert(decimal == 18, Errors::INVALID_DECIMALS);
    }

    #[test]
    fn test_total_supply() {
        let address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address: address };
        let total_supply = dispatcher.get_total_supply();
        assert(total_supply == 1000000, Errors::UNMATCHED_SUPPLY);
    }

    #[test]
    fn test_address_balance() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        let balance = dispatcher.get_total_supply();
        let admin_balance = dispatcher.balance_of(Account::admin());
        assert(admin_balance == balance, Errors::INVALID_BALANCE);

        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.transfer(Account::user1(), 10);
        let new_admin_balance = dispatcher.balance_of(Account::admin());
        new_admin_balance.print();
        assert(new_admin_balance == balance - 10, Errors::INVALID_BALANCE);
        stop_prank(CheatTarget::One(contract_address));

        let user1_balance = dispatcher.balance_of(Account::user1());
        assert(user1_balance == 10, Errors::INVALID_BALANCE);
    }

    #[test]
    #[fuzzer(runs: 22, seed: 38)]
    fn test_allowance(amount: u256) {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };

        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.approve(contract_address, amount);
        assert(
            dispatcher.allowance(Account::admin(), contract_address) == amount, Errors::INVALID_BALANCE
        );
        stop_prank(CheatTarget::One(contract_address));
    }

    #[test]
    fn test_transfer() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.transfer(Account::user1(), 10);
        let user1_balance = dispatcher.balance_of(Account::user1());
        assert(user1_balance == 10, Errors::INVALID_BALANCE);

        stop_prank(CheatTarget::One(contract_address));
    }

    #[test]
    fn test_transfer_from() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        let user1 = Account::user1();
        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.approve(user1, 10);
        assert(dispatcher.allowance(Account::admin(), user1) == 10, Errors::NOT_ALLOWED);
        stop_prank(CheatTarget::One(contract_address));

        start_prank(CheatTarget::One(contract_address), user1);
        dispatcher.transfer_from(Account::admin(), Account::user2(), 5);
        assert(dispatcher.balance_of(Account::user2()) == 5, Errors::INVALID_BALANCE);
        // dispatcher.transfer_from(Account::admin(), user1, 15);
        // assert(dispatcher.balance_of(user1) == 5, Errors::INVALID_BALANCE);
        stop_prank(CheatTarget::One(contract_address));
    }

    #[test]
    #[should_panic(expected: ('Amount Not Allowed', ))]
    fn test_transfer_from_should_fail() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher {contract_address};
        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.approve(Account::user1(), 20);
        stop_prank(CheatTarget::One(contract_address));

        start_prank(CheatTarget::One(contract_address), Account::user1());
        dispatcher.transfer_from(Account::admin(), Account::user2(), 40);
    }

    #[test]
    #[should_panic(expected: ('You have no token approved', ))]
    fn test_transfer_from_failed_when_not_approved() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        start_prank(CheatTarget::One(contract_address), Account::user1());
        dispatcher.transfer_from(Account::admin(), Account::user2(), 5);
    }


    mod Errors {
        const INVALID_DECIMALS: felt252 = 'Invalid decimals';
        const UNMATCHED_SUPPLY: felt252 = 'Unmatched supply';
        const INVALID_BALANCE: felt252 = 'Invalid balance';
        const NOT_ALLOWED: felt252 = 'Not allowed';
    }

    mod Account {
        use core::option::OptionTrait;
        use starknet::ContractAddress;
        use core::traits::TryInto;

        fn user1() -> ContractAddress {
            'joy'.try_into().unwrap()
        }

        fn user2() -> ContractAddress {
            'caleb'.try_into().unwrap()
        }
        fn admin() -> ContractAddress {
            'admin'.try_into().unwrap()
        }
    }
}

