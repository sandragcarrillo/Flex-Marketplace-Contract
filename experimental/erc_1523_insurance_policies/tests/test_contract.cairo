use starknet::ContractAddress;
use starknet::testing::set_caller_address;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use erc1523::ERC1523::{ERC1523Contract, ERC1523ContractTrait};
use erc1523::IERC1523;

fn deploy_contract() -> ContractAddress {
    let contract = declare('ERC1523');
    contract.deploy(@ArrayTrait::new()).unwrap()
}

#[test]
fn test_mint_policy() {
    let contract_address = deploy_contract();
    let contract = ERC1523Contract::from_address(contract_address);

    let owner = contract_address_const::<0x1>();
    let token_id = 1_u256;
    
    set_caller_address(owner);

    contract.mint_policy(
        owner,
        token_id,
        'Test Carrier',
        'Test Risk',
        'Active',
        Option::Some('Test Parameters'),
        Option::Some('Test Terms'),
        Option::Some(1000),
        Option::Some(10000)
    );

    let carrier = contract.policy_metadata(token_id, keccak('carrier'));
    assert(carrier == 'Test Carrier', 'Incorrect carrier');

    let status = contract.policy_metadata(token_id, keccak('status'));
    assert(status == 'Active', 'Incorrect status');
}

#[test]
fn test_update_policy_status() {
    let contract_address = deploy_contract();
    let contract = ERC1523Contract::from_address(contract_address);

    let owner = contract_address_const::<0x1>();
    let token_id = 1_u256;
    
    set_caller_address(owner);

    contract.mint_policy(
        owner,
        token_id,
        'Test Carrier',
        'Test Risk',
        'Active',
        Option::Some('Test Parameters'),
        Option::Some('Test Terms'),
        Option::Some(1000),
        Option::Some(10000)
    );

    contract.update_policy_status(token_id, 'Inactive');

    let status = contract.policy_metadata(token_id, keccak('status'));
    assert(status == 'Inactive', 'Status not updated');
}

#[test]
fn test_policy_metadata() {
    let contract_address = deploy_contract();
    let contract = ERC1523Contract::from_address(contract_address);

    let owner = contract_address_const::<0x1>();
    let token_id = 1_u256;
    
    set_caller_address(owner);

    contract.mint_policy(
        owner,
        token_id,
        'Test Carrier',
        'Test Risk',
        'Active',
        Option::Some('Test Parameters'),
        Option::Some('Test Terms'),
        Option::Some(1000),
        Option::Some(10000)
    );

    let carrier = contract.policy_metadata(token_id, keccak('carrier'));
    assert(carrier == 'Test Carrier', 'Incorrect carrier');

    let risk = contract.policy_metadata(token_id, keccak('risk'));
    assert(risk == 'Test Risk', 'Incorrect risk');

    let premium = contract.policy_metadata(token_id, keccak('premium'));
    assert(premium == 1000, 'Incorrect premium');

    let sum_insured = contract.policy_metadata(token_id, keccak('sum_insured'));
    assert(sum_insured == 10000, 'Incorrect sum insured');
}