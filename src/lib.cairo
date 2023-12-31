use starknet::ContractAddress;

#[starknet::interface]
trait OwnableTrait<T> {
    fn transfer_ownership(ref self: T, new_owner: ContractAddress);
    fn get_owner(self: @T) -> ContractAddress;
    fn read_message(self: @T) -> felt252;
    fn change_message(ref self: T, new_message: felt252);
    fn read_score(self: @T, keyval: felt252) -> u32;
    fn read_all_scores(self: @T) -> Array<(felt252, u32)>;
    fn add_new_score(ref self: T, keyval: felt252, scoreval: u32);
}

#[starknet::contract]
mod Ownable {
    use super::ContractAddress;
    use starknet::get_caller_address;
    use array::ArrayTrait;

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
        score_size: u32,
        keys: LegacyMap<u32, felt252>,
        scores: LegacyMap<felt252, u32>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_owner: ContractAddress) {
        self.owner.write(init_owner);
        self.mess.write('great');
        self.score_size.write(0);
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

        fn read_message(self: @ContractState) -> felt252 {
            self.mess.read()
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

        fn read_score(self: @ContractState, keyval: felt252) -> u32 {
            self.scores.read(keyval)
        }

        fn read_all_scores(self: @ContractState) -> Array<(felt252, u32)> {
            let s = self.score_size.read();
            let mut arr = ArrayTrait::new();
            let mut i = 0;
            loop {
                if i > s {
                    break ();
                }
                let mut name = self.keys.read(i);
                let mut score = self.scores.read(name);
                arr.append((name, score));
                i += 1;
            };
            arr
            
        }

        fn add_new_score(ref self: ContractState, keyval: felt252, scoreval: u32) {
            let current_val = self.scores.read(keyval);
            if current_val == 0 {
                let size = self.score_size.read();
                self.keys.write(size, keyval);
                self.scores.write(keyval, scoreval);
                self.score_size.write(size + 1);
            }
            else {
                self.scores.write(keyval, scoreval);
            }
            
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

#[cfg(test)]
mod tests{
    use demo::Ownable;
    use demo::{OwnableTraitDispatcher, OwnableTraitDispatcherTrait};
    use starknet::{ContractAddress,Into, TryInto, OptionTrait};
    use starknet::syscalls::deploy_syscall;
    use starknet::get_caller_address;
    use result::ResultTrait;
    use array::{ArrayTrait, SpanTrait};
    


    #[test]
    #[available_gas(1000000)]
    fn owner_unit_test(){
        
        let admin: ContractAddress = 'admin'.try_into().unwrap();
        let mut calldata = array![admin.into()];
        let (address0, _) = deploy_syscall(Ownable::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false).unwrap();
        let mut contract0 = OwnableTraitDispatcher{contract_address: address0};
        assert (admin == contract0.get_owner(), 'not the owner');
        

    }


    #[test]
    #[available_gas(1000000)]
    fn message_unit_test(){
        
        let admin: ContractAddress = 'admin'.try_into().unwrap();
        let mut calldata = array![admin.into()];
        let (address0, _) = deploy_syscall(Ownable::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false).unwrap();
        let mut contract0 = OwnableTraitDispatcher{contract_address: address0};
        assert ('great' == contract0.read_message(), 'not the right message');
        

    }

   


    #[test]
    #[available_gas(10000000)]
    fn message_change_unit_test(){
        
        let admin: ContractAddress = get_caller_address();
        let mut calldata = array![admin.into()];
        let (address0, _) = deploy_syscall(Ownable::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false).unwrap();
        let mut contract0 = OwnableTraitDispatcher{contract_address: address0};
        contract0.change_message('good');
        assert ('good' == contract0.read_message(), 'not the right message');
        

    }
}