#[starknet::contract]
mod OnchainIdContract {
    use starknet::storage::StoragePathEntry;
    use starknet::get_caller_address;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use acl::onchain_id::interface::{ICompliantToken, Topic};
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        claims: Map<Topic, Map<ContractAddress, bool>>,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl ICompliantTokenImpl of ICompliantToken<ContractState> {
        fn add_claim(ref self: ContractState, topic: Topic) {
            let issuer = get_caller_address();
            self.claims.entry(topic).write(issuer, true);
        }

        fn claim_exists(ref self: ContractState, topic: Topic, issuer: ContractAddress) -> bool {
            self.claims.entry(topic).read(issuer)
        }
    }
}
