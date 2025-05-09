#[starknet::contract]
pub mod identity_registry {
    use starknet::{ContractAddress, SyscallResultTrait, ClassHash, get_caller_address};
    use starknet::storage::{Map, StorageMapWriteAccess, StorageMapReadAccess, StoragePointerReadAccess, StoragePointerWriteAccess};
    use crate::identity_registry::interface::IIdentityRegistry;
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::syscalls:: deploy_syscall ;

    component!(path: OwnableComponent, storage: ownable, event: ownable);

    // Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternal = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    pub struct Storage {
        // Maps user addresses to their Onchain_id contract.
        identity: Map<ContractAddress, ContractAddress>,
        onchainid_class_hash: ClassHash,
        onchain_id_salt: felt252,
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
    fn constructor(ref self: ContractState, onchainid_hash: ClassHash) {
        self.ownable.initializer(get_caller_address());
        self.onchainid_class_hash.write(onchainid_hash);
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

        fn get_new_identity(ref self: ContractState, user: ContractAddress) ->  ContractAddress {
            self.onchain_id_salt.write(self.onchain_id_salt.read() + 1);
            let (onchain_id_address, _) = deploy_syscall(
                self.onchainid_class_hash.read(),
                self.onchain_id_salt.read(),
                array![].span(),
                true,
            )
                .unwrap_syscall();


            self.register_identity(user, onchain_id_address);            
            onchain_id_address
        }


        fn register_my_identity(ref self: ContractState, identity: ContractAddress) {
            let caller = get_caller_address();
            self.register_identity(caller, identity);
        }
    }
}
