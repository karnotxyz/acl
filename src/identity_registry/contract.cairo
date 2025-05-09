#[starknet::contract]
pub mod identity_registry {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StorageMapWriteAccess, StorageMapReadAccess};
    use crate::identity_registry::interface::IIdentityRegistry;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: ownable);

    // Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternal = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    pub struct Storage {
        // Maps user addresses to their Onchain_id contract.
        identity: Map<ContractAddress, ContractAddress>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ownable: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.ownable.initializer(get_caller_address());
    }


    #[abi(embed_v0)]
    impl IIdentityRegistryImpl of IIdentityRegistry<ContractState> {
        fn register_identity(
            ref self: ContractState, user_address: ContractAddress, identity: ContractAddress,
        ) {
            assert(get_caller_address() == self.ownable.owner(), 'Caller not the owner');
            self.identity.write(user_address, identity);
        }

        fn get_identity(self: @ContractState, user_address: ContractAddress) -> ContractAddress {
            self.identity.read(user_address)
        }

        fn register_my_identity(ref self: ContractState, identity: ContractAddress) {
            let caller = get_caller_address();
            self.register_identity(caller, identity);
        }
    }
}
