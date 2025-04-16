use starknet::ContractAddress;

#[starknet::interface]
pub trait IAcl<TContractState> {
    fn give_approval(
        ref self: TContractState, function_selector: felt252, to: ContractAddress, args: Span<felt252>
    );
    fn is_approved(
        self: @TContractState, caller: ContractAddress, args: Span<felt252>
    ) -> bool;
}
