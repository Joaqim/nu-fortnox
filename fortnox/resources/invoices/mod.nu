use ../bool_flags_to_filter.nu
use ../parse_actions_from_params.nu
use ../fetch_fortnox_resource.nu
use ../parse_ids_and_body_from_input.nu
use ../../../utils/ratelimit_sleep.nu
use ../../../utils/get_daterange_from_params.nu
use ../../../utils/compact_record.nu
use ../create_fortnox_resource_url.nu
use ../fortnox_request.nu

use std log

def _fortnox_invoice_number__completion [$context: string] -> list<int> {
    try {
        return (fetch_fortnox_resource "invoices" {limit: 10, sortby: 'documentnumber', sortorder: 'descending' } | get Invoices.DocumentNumber)
    }
    return []
}

const $method_completions = ['put', 'post', 'get']
def _fortnox_invoices_method__completion [$context: string] -> list<string> {
    ($method_completions)
}
const $filter_completions = [unbooked cancelled fullypaid unpaid unpaidoverdue]
def _fortnox_invoices_filter__completion [$context: string] -> list<string> {
    ($filter_completions)
}


def _fortnox_invoices_action__completion [$context: string] -> list<string> {
    let $params = ($context | split words | find --regex 'put|post|get' -i)
    (match $params.0? {
        'put' => {['update', 'bookkeep', 'cancel', 'credit', 'externalprint', 'warehouseready']}
        'post' => {['create']}
        'get' => {['print', 'email', 'printreminder', 'preview', 'eprint', 'einvoice']}
        _ => {[]}
    })
}

#export def _test_ [$context?: string] { (_fortnox_invoices_action__completion ($context | default 'nu-fortnox fortnox invoices 53155 get ')) }

# Returns an empty list if no resources was found
export def main [
    method?: string@_fortnox_invoices_method__completion = 'get', # Perform PUT, POST or GET action for invoice at Fortnox API
    action?: string@_fortnox_invoices_action__completion = ''
    --invoice-number (-i): int@_fortnox_invoice_number__completion # Get a known invoice by its invoice number
    #--put-action: string # Perform PUT action for invoice number: 'update', 'bookkeep' 'cancel', 'credit', 'externalprint', 'warehouseready'
    #--post-action: string # Perform POST action for invoice number: 'create'
    #--get-action: string # Perform GET action for invoice number: 'print', 'email', 'printreminder', 'preview', 'eprint', 'einvoice'
    --body: any # Request body to POST or PUT to Fortnox API for actions: 'create' or 'update'
    --filter-by-your-order-number (-f): string, # Filter by 'YourOrderNumber'
    --customer-name (-c): string, # Filter by 'CustomerName'

    --last-modified (-m): datetime, # Filter by last modification date for Fortnox documents

    --from-date (-s): string, # Fortnox 'fromdate' param, expects 'YYYY-M-D'
    --to-date (-e): string, # Fortnox 'todate' param, expects 'YYYY-M-D, cannot not be used without 'from-date', 'from', 'date' or 'for-[year quarter month day]
    --date (-d): string, # Sets both 'fromdate' and 'todate' to this value
    --from: string, # From date in readable duration string, see 'into datetime -h'

    --for-year (-Y): int, # Specify from/to date range by year, expects integer above 1970
    --for-quarter (-Q): int, # Specify from/to date range by quarter, expects integer [1-4]
    --for-month (-M): int, # Specify from/to date range by month, expects integer [1-12]
    --for-day (-D): int, # Specify from/to date range by day, expects integer [1-32]

    --filter: string@_fortnox_invoices_filter__completion, # Filters for invoices:  'unbooked', 'cancelled', 'fullypaid', 'unpaid', 'unpaidoverdue'
    --no-cache, # Don't use cache for request.
    --dry-run, # Dry run, log the Fortnox API url, returns 'nothing'

    --brief (-b), # Remove empty values
    --obfuscate (-O), # Remove Customer's info, but not customer's country
    --with-pagination (-P), # Return result includes Fortnox 'MetaInformation' for pagination: @TotalResource, @TotalPages, @CurrentPage
    --raw, # Returns least modified Fortnox response, --raw is mutually exclusive with --brief and --obfuscate --with-pagination ( will be used as 'true')

    --limit (-l): int = 100, # Limit how many resources to fetch, expects integer [1-100]
    --page (-p): range = 1..1, # If range is higher than 1..1, limit must be set to 100
    --sort-by (-s): string = 'documentnumber', # Set 'sortby' param for Fortnox request
    --sort-order (-s): string = 'descending', # Set 'sortorder' param for Fortnox Request, expects 'ascending' or 'descending'
] -> record {
    let $data = (parse_ids_and_body_from_input "invoices" $in --id $invoice_number --body $body)

    let $fortnox_action = (parse_actions_from_params "invoices" $method $action --id $data.id --ids $data.ids --body $data.body)

    if not ($filter | is-empty) and not ($invoice_number | is-empty) {
        error make {
            msg: $"Unexpected '--filter' used while providing an invoice number in arguments"
            label: {
                text: $"Filtering by invoice number and filter at the same time is not supported"
                span: (metadata $filter).span
            }
        }
    }

    let $date_range = (
        get_daterange_from_params
            --for-year $for_year
            --for-quarter $for_quarter
            --for-month $for_month
            --for-day $for_day
            --date $date
            --from-date $from_date
            --to-date $to_date
            --to-date-precision 1day # Fortnox uses date format: %Y-%m-%d, so the last day in a month would be where a date range (--month) would end at 01-01 -> 01->31.
            --from $from
    )

    def _fetch [$id, $params, --page=1..1, --disable-pagination]: {
        (fetch_fortnox_resource "invoices"
            --id $id
            --page $page 
            --brief=($brief)
            --obfuscate=($obfuscate)
            --no-cache=($no_cache)
            --with-pagination=((not $disable_pagination) and $with_pagination)
            --dry-run=($dry_run)
            --raw=($raw)
            $params
        )
    }
    def _post_or_put [$id]: {
        (fetch_fortnox_resource "invoices" --method $method --action $action --id $id --body $data.body --dry-run=($dry_run))
    }

    if ($method != 'get' and not ($fortnox_action | is-empty)) {
        if not ($data.ids | is-empty) {
            mut $invoices_result = [] 
            for $id in $data.ids {
                $invoices_result = ($invoices_result | append (_post_or_put $id).Invoice?)
            }
            return { Invoices: $invoices_result }
        } else {

            let $url = (create_fortnox_resource_url "invoices" --id $data.id --action $fortnox_action )
            if ($dry_run) {
                log info $"Dry-run: ($method) @ ($url) - body: ($body | to nuon)"
                return
            }
            return ( fortnox_request $method $url --body $body)
        }
    }

    if ($data.ids | is-empty) {
        # Fetch single invoice by it's id
        return (
            _fetch $data.id {
                    limit: $limit,
                    sortby: $sort_by,
                    sortorder: $sort_order,
                    lastmodified: $last_modified,

                    fromdate: $date_range.from,
                    todate: $date_range.to,

                    yourordernumber: $filter_by_your_order_number,
                    filter: $filter
            }
        )
    } else {
        # Fetch multiple invoices by their ids
        let $invoices = (
            $data.ids 
            | each { 
                _fetch $in --disable-pagination {
                    limit: 1
                }
            }
        )

        if (($invoices | describe) == 'list<list<any>>')  {

            log info 'Invoices as list<list<any>>'
            return { Invoices: ($invoices | each { into record } | flatten) }
        }

        
        if not ($invoices.Invoice? | is-empty ) {
            log info 'Invoices as record<Invoice>'
            return { Invoices: $invoices.Invoice }
        }
        log info ($"Invoices as $(invoices | describe)")
        return { Invoices: ($invoices | flatten | into record ) }
    }
}
