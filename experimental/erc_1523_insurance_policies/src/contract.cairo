use openzeppelin.token.erc721.library as ERC721;
use starknet::ContractAddress;
use starknet::core::storage::LegacyMap;
use starknet::crypto::hash::keccak;
use cairo_lang::bytearray::ByteArray; // Import for ByteArray handling

#[starknet::interface]
trait IERC1523<TContractState> {
    fn policy_metadata(self: @TContractState, token_id: u256, property_path_hash: felt252) -> felt252;
}

#[starknet::contract]
mod ERC1523 {
    use starknet::ContractAddress;
    use super::IERC1523;
    use openzeppelin.token.erc721.library as ERC721;
    use cairo_lang::bytearray::ByteArray; 

    #[storage]
    struct Storage {
        policies: LegacyMap::<u256, PolicyInfo>,
    }

    #[derive(Drop, Serde)]
    struct PolicyInfo {
        carrier: felt252,   
        risk: felt252,      
        status: felt252,    
        parameters: Option<ByteArray>,  
        terms: Option<ByteArray>,    
        premium: Option<felt252>,       
        sum_insured: Option<felt252>,   
    }

    #[external(v0)]
    impl IERC1523Impl of super::IERC1523<ContractState> {
        fn policy_metadata(self: @ContractState, token_id: u256, property_path_hash: felt252) -> felt252 {
            let policy_info = self.policies.read(token_id).unwrap();
            
            if property_path_hash == keccak("carrier") {
                return policy_info.carrier;
            }
            if property_path_hash == keccak("risk") {
                return policy_info.risk;
            }
            if property_path_hash == keccak("status") {
                return policy_info.status;
            }
            if property_path_hash == keccak("premium") {
                return policy_info.premium.unwrap_or(0);
            }
            if property_path_hash == keccak("sum_insured") {
                return policy_info.sum_insured.unwrap_or(0);
            }

            return 0;
        }
    }

    #[external(v0)]
    fn mint_policy(
        ref self: ContractState,
        to: ContractAddress,
        token_id: u256,
        carrier: felt252,
        risk: felt252,
        status: felt252,
        parameters: Option<ByteArray>, 
        terms: Option<ByteArray>,       
        premium: Option<felt252>,
        sum_insured: Option<felt252>
    ) {
        
        ERC721::_mint(to, token_id);

        self.policies.write(token_id, PolicyInfo { 
            carrier, 
            risk, 
            status, 
            parameters, 
            terms, 
            premium, 
            sum_insured 
        });
    }

    #[external(v0)]
    fn update_policy_status(
        ref self: ContractState,
        token_id: u256,
        new_status: felt252
    ) {
        let mut policy_info = self.policies.read(token_id).unwrap();
        policy_info.status = new_status;
        self.policies.write(token_id, policy_info);
    }
}
