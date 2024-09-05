use ./fetch_fortnox_resource.nu
use ./utils/fortnox_resource_url.nu
use ./fortnox_request.nu
use ./financialyears/


export def main [
    --voucher-series (-s): string
    --voucher-number (-i): int
    --no-cache
    ] {

    let $url: string = (fortnox_resource_url 'vouchers' --additional-path $voucher_series --id $voucher_number)
    (fortnox_request 'get' $url --no-cache=($no_cache))
}

def _fortnox_vouchers_financialyear__completion [] -> list<string> {
    (financialyears --no-cache=(false) | get FinancialYears.FromDate | parse '{year}-{_m}-{_d}' | get year)
}

export def 'list' [
    --voucher-series (-s): string
    --financial-year: string@_fortnox_vouchers_financialyear__completion
    --from-date: string
    --to-date: string
    --no-cache

    --page: range = 1..1
    --limit: int = 100

    --brief
    --obfuscate
    --with-pagination
    --dry-run
    --raw
    ] {

    def internal_params [] {
        {
            pages: $page
            brief: $brief
            obfuscate: $obfuscate
            no_cache: $no_cache
            with_pagination: $with_pagination
            additional_path: ''
            dry_run: $dry_run
            raw: $raw
        }
    }
    def _get_financialyears_id [] {
        mut $date: string = ($from_date | default $to_date )

        if ($date | is-empty) {
            if ($financial_year | is-empty) {
                $date = (date now | format date "%Y-%m-%d")
            } else {
                $date = $"($financial_year)-01-01"
            }
        }

        (financialyears --no-cache=(false) --filter-by-date=($date) | get FinancialYears.0.Id)
    }

    (fetch_fortnox_resource 'vouchers' (internal_params) {
        limit: $limit
        financialyear: (_get_financialyears_id)
        voucherseries: $voucher_series
        fromdate: $from_date
        todate: $to_date
    })
}