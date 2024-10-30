#[starknet::contract]
mod ERC1523 {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use openzeppelin::token::erc721::interface::IERC721;
    use starknet::ClassHash;
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[derive(Drop, Copy, Serde, starknet::Store)]
    enum PolicyStatus {
        Active,
        Underwritten,
        Expired
    }

    #[derive(Drop, Copy, Serde, starknet::Store)]
    struct PolicyMetadata {
        carrier: ContractAddress,
        risk: felt252,
        status: PolicyStatus,
        premium: u256,
        sum_insured: u256,
        expiration_time: u64,
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        policy_metadata: LegacyMap<u256, PolicyMetadata>,
        total_policies: u256,
        policy_ids: LegacyMap<u256, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        PolicyCreated: PolicyCreated,
        PolicyStatusUpdated: PolicyStatusUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct PolicyCreated {
        token_id: u256,
        carrier: ContractAddress,
        risk: felt252,
        premium: u256,
        sum_insured: u256
    }

    #[derive(Drop, starknet::Event)]
    struct PolicyStatusUpdated {
        token_id: u256,
        new_status: PolicyStatus
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let name: ByteArray = "FlexInsurance";
        let symbol: ByteArray = "FINS";
        let base_uri: ByteArray = "";
        self.erc721.initializer(name, symbol, base_uri);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn safe_mint(
            ref self: ContractState,
            recipient: ContractAddress,
            token_id: u256,
            data: Span<felt252>,
        ) {
            self.ownable.assert_only_owner();
            self.erc721._safe_mint(recipient, token_id, data);
        }

        #[external(v0)]
        fn safeMint(
            ref self: ContractState,
            recipient: ContractAddress,
            tokenId: u256,
            data: Span<felt252>,
        ) {
            self.safe_mint(recipient, tokenId, data);
        }

        #[external(v0)]
        fn create_policy(
            ref self: ContractState,
            recipient: ContractAddress,
            carrier: ContractAddress,
            risk: felt252,
            premium: u256,
            sum_insured: u256,
            expiration_time: u64,
        ) -> u256 {
            self.ownable.assert_only_owner();
            
            let token_id = self.total_policies.read() + 1;
            self.total_policies.write(token_id);
            
            let metadata = PolicyMetadata {
                carrier,
                risk,
                status: PolicyStatus::Underwritten,
                premium,
                sum_insured,
                expiration_time,
            };
            self.policy_metadata.write(token_id, metadata);
            
            self.erc721._mint(recipient, token_id);
            
            self.policy_ids.write(token_id, token_id);
            
            self.emit(PolicyCreated { token_id, carrier, risk, premium, sum_insured });
            
            token_id
        }

        #[external(v0)]
        fn get_policy_metadata(self: @ContractState, token_id: u256) -> PolicyMetadata {
            assert(self.erc721._exists(token_id), 'Policy does not exist');
            self.policy_metadata.read(token_id)
        }

        #[external(v0)]
        fn update_policy_status(ref self: ContractState, token_id: u256, new_status: PolicyStatus) {
            self.ownable.assert_only_owner();
            assert(self.erc721._exists(token_id), 'Policy does not exist');
            
            let mut metadata = self.policy_metadata.read(token_id);
            metadata.status = new_status;
            self.policy_metadata.write(token_id, metadata);
            
            self.emit(PolicyStatusUpdated { token_id, new_status });
        }

        #[external(v0)]
        fn total_policies(self: @ContractState) -> u256 {
            self.total_policies.read()
        }

        #[external(v0)]
        fn get_policy_by_index(self: @ContractState, index: u256) -> u256 {
            assert(index < self.total_policies.read(), 'Index out of bounds');
            self.policy_ids.read(index + 1)
        }
    }

    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
}
