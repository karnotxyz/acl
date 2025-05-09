#[starknet::interface]
pub trait ICompliance<TState> {
    fn set_fee(ref self: TState, fee: u8);
    fn get_fee(self: @TState) -> u8;
}
