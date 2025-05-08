#[starknet::component]
pub mod AclComponent {
    use acl::acl::interface::IAcl;
    use core::poseidon;
    use starknet::ContractAddress;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    #[storage]
    pub struct Storage {
        approvals: Map<(felt252, felt252, ContractAddress), bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {}

    #[embeddable_as(AclImpl)]
    pub impl Acl<
        TContractState, +HasComponent<TContractState>,
    > of IAcl<ComponentState<TContractState>> {
        fn give_approval(
            ref self: ComponentState<TContractState>,
            function_selector: felt252,
            to: ContractAddress,
            args: Span<felt252>,
        ) {
            let hash = poseidon::poseidon_hash_span(args);
            self.approvals.write((function_selector, hash, to), true);
        }
    }

    #[generate_trait]
    pub impl IAclInternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of IAclInternal<TContractState> {
        fn is_approved(self: @ComponentState<TContractState>, args: Span<felt252>) -> bool {
            let hash = poseidon::poseidon_hash_span(args);
            let execution_info = starknet::get_execution_info().unbox();
            let approved_till = self
                .approvals
                .read((execution_info.entry_point_selector, hash, starknet::get_caller_address()));
            approved_till
        }
    }
}
