pub type InvoiceId = felt252;

#[starknet::interface]
pub trait IInvoiceRegistry<TState> {
    fn add_invoice(ref self: TState, invoice_id: InvoiceId);
    fn lend_invoice(ref self: TState, invoice_id: InvoiceId);
}
