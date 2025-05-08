use starknet::ContractAddress;

pub type Topic = felt252;

#[starknet::interface]
pub trait ICompliantToken<TState> {
    fn add_claim(ref self: TState, topic: Topic);
    fn claim_exists(ref self: TState, topic: Topic, issuer: ContractAddress) -> bool;
}
