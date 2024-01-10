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
        // self.name.write(_name);
        // self.symbol.write(_symbol);
        // self.decimals.write(_decimal);
        // self.total_supply.write(_initial_supply);
        // self.balances.write(recipient, _initial_supply);
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
            assert(my_allowance > 0, 'Not approved to spend!');
            assert(amount <= my_allowance, 'Amount Not Allowed');
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


// Annotation
#[cfg(test)]
mod test {
    use core::serde::Serde;
    use super::{IERC20, BWCERC20Token, IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::ContractAddress;
    use starknet::contract_address::contract_address_const;
    use array::ArrayTrait;
    use snforge_std::{declare, ContractClassTrait, fs::{FileTrait, read_txt}};
    use snforge_std::{start_prank, stop_prank, CheatTarget};
    use snforge_std::PrintTrait;
    use traits::{Into, TryInto};

    // We first have to deploy first via a helper function
    fn deploy_contract() -> ContractAddress {
        // Before deploying a starknet contract, we need a contract_class.
        // Get it using the declare function from starknetFoundry
        let erc20contract_class = declare('BWCERC20Token');

        // Supply values the constructor arguements when deploying
        // REMEMBER: It has to be in an array
        let file = FileTrait::new('data/constructor_args.txt');
        let constructor_args = read_txt(@file);
        let contract_address = erc20contract_class.deploy(@constructor_args).unwrap();
        contract_address
    }

    // Generate an address
    mod Account {
        use starknet::ContractAddress;
        use traits::TryInto;

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


    // --------------------- Now we start testing --------------------------------

    // Test 1 - Test wether we can get the name
    #[test]
    fn test_constructor() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        // let name = dispatcher.get_name();
        let name = dispatcher.get_name();

        assert(name == 'BlockheaderToken', 'name is not correct');
    }

    #[test]
    fn test_decimal_is_correct() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        let decimal = dispatcher.get_decimals();

        assert(decimal == 18, 'Decimal is not correct');
    }

    #[test]
    fn test_total_supply() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        let total_supply = dispatcher.get_total_supply();

        assert(total_supply == 1000000, 'Total supply is wrong');
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
        assert(new_admin_balance == balance - 10, Errors::INVALID_BALANCE);
        stop_prank(CheatTarget::One(contract_address));

        let user1_balance = dispatcher.balance_of(Account::user1());
        assert(user1_balance == 10, Errors::INVALID_BALANCE);
    }

    #[test]
    fn test_allowance() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };

        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.approve(contract_address, 20);

        let currentAllowance = dispatcher.allowance(Account::admin(), contract_address);

        assert(currentAllowance == 20, Errors::INVALID_ALLOWANCE_GIVEN);
        stop_prank(CheatTarget::One(contract_address));
    }

    #[test]
    fn test_transfer() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };

        // Get original balances
        let original_sender_balance = dispatcher.balance_of(Account::admin());
        let original_recipient_balance = dispatcher.balance_of(Account::user1());

        start_prank(CheatTarget::One(contract_address), Account::admin());

        dispatcher.transfer(Account::user1(), 50);

        // Confirm that the funds have been sent!
        assert(
            dispatcher.balance_of(Account::admin()) == original_sender_balance - 50,
            Errors::FUNDS_NOT_SENT
        );

        // Confirm that the funds have been recieved!
        assert(
            dispatcher.balance_of(Account::user1()) == original_recipient_balance + 50,
            Errors::FUNDS_NOT_RECIEVED
        );

        stop_prank(CheatTarget::One(contract_address));
    }


    #[test]
    fn test_transfer_from() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };

        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.approve(Account::user1(), 20);
        stop_prank(CheatTarget::One(contract_address));

        assert(
            dispatcher.allowance(Account::admin(), Account::user1()) == 20,
            Errors::INVALID_ALLOWANCE_GIVEN
        );

        start_prank(CheatTarget::One(contract_address), Account::user1());
        dispatcher.transfer_from(Account::admin(), Account::user2(), 10);
        assert(
            dispatcher.allowance(Account::admin(), Account::user1()) == 10, Errors::FUNDS_NOT_SENT
        );
        stop_prank(CheatTarget::One(contract_address));
    }

    #[test]
    #[should_panic(expected: ('Not approved to spend!',))]
    fn test_not_approved_to_spend_error() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };
        start_prank(CheatTarget::One(contract_address), Account::user1());
        dispatcher.transfer_from(Account::admin(), Account::user2(), 40);
    }

    #[test]
    #[should_panic(expected: ('Amount Not Allowed',))]
    fn test_should_panic_when_amount_transferred_not_allowed() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };

        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.approve(Account::user1(), 20);
        stop_prank(CheatTarget::One(contract_address));

        assert(
            dispatcher.allowance(Account::admin(), Account::user1()) == 20,
            Errors::INVALID_ALLOWANCE_GIVEN
        );

        start_prank(CheatTarget::One(contract_address), Account::user1());
        dispatcher.transfer_from(Account::admin(), Account::user2(), 80);
    }

    #[test]
    fn test_approve() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };

        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.approve(Account::user1(), 50);
        assert(
            dispatcher.allowance(Account::admin(), Account::user1()) == 50,
            Errors::INVALID_ALLOWANCE_GIVEN
        );
    }

    #[test]
    fn test_increase_allowance() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };

        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.approve(Account::user1(), 30);
        assert(
            dispatcher.allowance(Account::admin(), Account::user1()) == 30,
            Errors::INVALID_ALLOWANCE_GIVEN
        );

        dispatcher.increase_allowance(Account::user1(), 20);

        assert(
            dispatcher.allowance(Account::admin(), Account::user1()) == 50,
            Errors::ERROR_INCREASING_ALLOWANCE
        );
    }

    #[test]
    fn test_decrease_allowance() {
        let contract_address = deploy_contract();
        let dispatcher = IERC20Dispatcher { contract_address };

        start_prank(CheatTarget::One(contract_address), Account::admin());
        dispatcher.approve(Account::user1(), 30);
        assert(
            dispatcher.allowance(Account::admin(), Account::user1()) == 30,
            Errors::INVALID_ALLOWANCE_GIVEN
        );

        dispatcher.decrease_allowance(Account::user1(), 5);

        assert(
            dispatcher.allowance(Account::admin(), Account::user1()) == 25,
            Errors::ERROR_DECREASING_ALLOWANCE
        );
    }

    // Custom errors for error handling
    mod Errors {
        const INVALID_DECIMALS: felt252 = 'Invalid decimals!';
        const UNMATCHED_SUPPLY: felt252 = 'Unmatched supply!';
        const INVALID_BALANCE: felt252 = 'Invalid balance!';
        const INVALID_ALLOWANCE_GIVEN: felt252 = 'Invalid allowance given';
        const FUNDS_NOT_SENT: felt252 = 'Funds not sent!';
        const FUNDS_NOT_RECIEVED: felt252 = 'Funds not recieved!';
        const ERROR_INCREASING_ALLOWANCE: felt252 = 'Allowance not increased';
        const ERROR_DECREASING_ALLOWANCE: felt252 = 'Allowance not decreased';
    }
}
