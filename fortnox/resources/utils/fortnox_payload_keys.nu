# 'invoices' -> [Invoice, Invoices], 'vouchers' -> [Voucher, Vouchers], etc...
export def main [resources: string] record<singular: string, plural: string> {
    (match ($resources) {
        "invoices" => {{singular: 'Invoice', plural: 'Invoices'}}
        _ => {
            error make {
                msg: "Unknown fortnox resource"
                label: {
                    text: $"Could not find Fortnox payload key for ($resources)"
                    span: (metadata $resources).span
                }
            }
        }
    })
}

