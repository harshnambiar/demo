use starknet::ContractAddress;
use demo::Ownable;
use demo::{OwnableTraitDispatcher, OwnableTraitDispatcherTrait};
use snforge_std::{declare, ContractClassTrait};
use starknet::get_caller_address;
use result::ResultTrait;
use array::{ArrayTrait, SpanTrait};
use snforge_std::{start_prank, stop_prank, start_mock_call, stop_mock_call};

mod Accounts {
    use traits::TryInto;
    use starknet::ContractAddress;
    fn admin() -> ContractAddress {
        'admin'.try_into().unwrap()
    }
    fn other() -> ContractAddress {
        'other'.try_into().unwrap()
    }
}

mod Errors {
    const INVALID_OWNER: felt252 = 'Not the correct owner';
    const INVALID_MESSAGE: felt252 = 'Not the correct message';
}


fn deploy_contract(name: felt252) -> ContractAddress {
    let contract = declare(name);

    let admin: ContractAddress = Accounts::admin();
    let mut calldata = array![admin.into()];
    contract.deploy(@calldata).unwrap()
}

#[test]
fn test_admin(){
    let contract_address = deploy_contract('Ownable');
    let dis = OwnableTraitDispatcher { contract_address  };
    let owner = dis.get_owner();
    assert (owner == Accounts::admin(), Errors::INVALID_OWNER);
}

#[test]
#[should_panic]
fn test_not_admin(){
    let contract_address = deploy_contract('Ownable');
    let dis = OwnableTraitDispatcher { contract_address  };
    let owner = dis.get_owner();
    assert (owner == Accounts::other(), 'not the owner');
}


#[test]
fn test_message(){
    let contract_address = deploy_contract('Ownable');
    let dis = OwnableTraitDispatcher { contract_address  };
    let mess = dis.read_message();
    assert (mess == 'great', Errors::INVALID_MESSAGE);
}


#[test]
#[should_panic]
fn test_unauth_message_change(){
    let contract_address = deploy_contract('Ownable');
    let dis = OwnableTraitDispatcher { contract_address  };
    start_prank(contract_address, Accounts::other());
    dis.change_message('nice');
    stop_prank(contract_address);
    assert (1 == 1, 'no error!');
}

#[test]
fn test_mock_message(){
    let contract_address = deploy_contract('Ownable');
    let dis = OwnableTraitDispatcher { contract_address  };
    let mock_ret_data: felt252 = 'mock';
    start_mock_call(contract_address, 'read_message', mock_ret_data);
    let new_msg = dis.read_message();
    stop_mock_call(contract_address, 'read_message');
    assert (new_msg == 'mock', 'message wasnt reset at all');
    assert (new_msg != dis.read_message(), 'message change permanent!');
}