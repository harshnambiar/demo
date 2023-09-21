use starknet::ContractAddress;

#[starknet::interface]
trait OwnableTrait<T> {
    fn transfer_ownership(ref self: T, new_owner: ContractAddress);
    fn get_owner(self: @T) -> ContractAddress;
    fn change_message(ref self: T, new_message: felt252);
}

#[starknet::contract]
mod Ownable {
    use super::ContractAddress;
    use starknet::get_caller_address;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
      OwnershipTransferred: OwnershipTransferred,  
      MessageRewritten: MessageRewritten,
    }

    

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        #[key]
        prev_owner: ContractAddress,
        #[key]
        new_owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct MessageRewritten {
        #[key]
        prev_message: felt252,
        #[key]
        new_message: felt252,
    }

    #[storage]
    struct Storage {
        owner: ContractAddress,
        mess: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_owner: ContractAddress) {
        self.owner.write(init_owner);
        self.mess.write('great');
    }

    #[external(v0)]
    impl OwnableImpl of super::OwnableTrait<ContractState> {
        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            self.only_owner();
            let prev_owner = self.owner.read();
            self.owner.write(new_owner);
            self.emit(Event::OwnershipTransferred(OwnershipTransferred {
                prev_owner: prev_owner,
                new_owner: new_owner,
            }));
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn change_message(ref self: ContractState, new_message: felt252) {
            self.only_owner();
            let prev_message = self.mess.read();
            self.mess.write(new_message);
            self.emit(Event::MessageRewritten(MessageRewritten {
                prev_message: prev_message,
                new_message: new_message,
            }));
        }
    }

    #[generate_trait]
    impl PrivateMethods of PrivateMethodsTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Caller is not the owner');
        }
    }
}