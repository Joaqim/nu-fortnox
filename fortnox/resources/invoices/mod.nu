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
        return (fetch_fortnox_resource "invoices" --no-cache {limit: 10, sortby: 'documentnumber', sortorder: 'descending' } | get Invoices.DocumentNumber)
    }
    return []
}

const $method_completions = ['put', 'post', 'get']
def _fortnox_invoices_method__completion [$context: string] -> list<string> {
    ($method_completions)
}

const $filter_completions = [cancelled fullypaid unpaid unpaidoverdue unbooked]
def _fortnox_invoices_filter__completion [$context: string] -> list<string> {
    ($filter_completions)
}

def _fortnox_invoices_action__completion [$context: string] -> list<string> {
    let $params = ($context | split words | find --regex 'put|post|get' -i)
    (match ($params | last) {
        'put' => {['update', 'bookkeep', 'cancel', 'credit', 'externalprint', 'warehouseready']}
        'post' => {['create']}
        'get' => {['print', 'email', 'printreminder', 'preview', 'eprint', 'einvoice', 'none']}
        _ => {[]}
    })
}

const $sort_by_completions = ["customername" "customernumber" "documentnumber" "invoicedate" "ocr" "total"]
def _fortnox_invoices_sort_by__completion [$context: string] -> list<string> {
    return $sort_by_completions
}

def _fortnox_invoices_sort_order__completion [$context: string] -> list<string> {
    return ['ascending', 'descending']
}


def _datetime_string__completion [$context: string] -> list<string> {
    # From:
    #(into datetime --list-human | get 'parseable human datetime examples')
    return (
        [
            "Today 08:30",
            "2022-11-07 13:25:30",
            "15:20 Friday",
            "Last Friday 17:00",
            "Last Friday at 19:45",
            "10 hours and 5 minutes ago",
            "1 years ago",
            "A year ago",
            "A month ago",
            "A week ago",
            "A day ago",
            "An hour ago",
            "A minute ago",
            "A second ago", 
            Now
        ]
    )
}

#export def _test_ [$context?: string] { (_fortnox_invoices_action__completion ($context | default 'nu-fortnox fortnox invoices 53155 get ')) }

# Returns an empty list if no resources was found
export def main [
    method: string@_fortnox_invoices_method__completion = 'get', # Perform PUT, POST or GET action for invoice at Fortnox API
    --action: string@_fortnox_invoices_action__completion = 'none'
    --invoice-number (-i): int@_fortnox_invoice_number__completion # Get a known invoice by its invoice number
    --filter: string@_fortnox_invoices_filter__completion, # Filters for invoices:  'unbooked', 'cancelled', 'fullypaid', 'unpaid', 'unpaidoverdue'

    --limit (-l): int = 100, # Limit how many resources to fetch, expects integer [1-100]
    --page (-p): range = 1..1, # If range is higher than 1..1, limit must be set to 100
    --sort-by (-s): string@_fortnox_invoices_sort_by__completion = 'documentnumber', # Set 'sortby' param for Fortnox request
    --sort-order (-s): string@_fortnox_invoices_sort_order__completion = 'descending', # Set 'sortorder' param for Fortnox Request, expects 'ascending' or 'descending'

    --body: any # Request body to POST or PUT to Fortnox API for actions: 'create' or 'update'

    --your-order-number (-f): string, # Returns list of Invoice(s) filtered by YourOrderNumber
    --customer-name (-c): string, # Returns list of Invoice(s) filtered by CustomerName
    --last-modified (-m): any, # Returns list of Invoice(s) filtered by last modified date 

    --from-date (-s): string, # Fortnox 'fromdate' param, expects 'YYYY-M-D'
    --to-date (-e): string, # Fortnox 'todate' param, expects 'YYYY-M-D, cannot not be used without 'from-date', 'from', 'date' or 'for-[year quarter month day]
    --date (-d): string, # Sets both 'fromdate' and 'todate' to this value, useful if you want a single day. Expects: 'YYYY-M-D'
    --from: string@_datetime_string__completion, # Fortnox 'fromdate' in a readable datetime string, see 'into datetime --list-human'

    --from-final-pay-date: string,
    --to-final-pay-date: string,

    --for-year (-Y): int, # Specify from/to date range by year, expects integer above 1970
    --for-quarter (-Q): int, # Specify from/to date range by quarter, expects integer [1-4]
    --for-month (-M): int, # Specify from/to date range by month, expects integer [1-12]
    --for-day (-D): int, # Specify from/to date range by day, expects integer [1-32]

    --no-cache, # Don't use cache for request.
    --dry-run, # Dry run, log the Fortnox API url, returns 'nothing'

    --brief (-b), # Filter out empty values from result
    --obfuscate (-O), # Filter out Confidential information. Does not remove not Country ISO codes
    --with-pagination (-P), # Return result includes Fortnox 'MetaInformation' for pagination: @TotalResource, @TotalPages, @CurrentPage
    --raw, # Returns least modified Fortnox response, --raw is mutually exclusive with --brief, --obfuscate and --with-pagination
] -> record {
    let $data = (parse_ids_and_body_from_input "invoices" $in --id $invoice_number --action $action --body $body)

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
            --to-date-precision 1day # Fortnox uses date format: %Y-%m-%d, so the last day in a month would be where a date range (--month) would encompass 01-01 -> 01->31.
            --from $from
    )

    def _fetch [$id: any, $params, --disable-pagination]: {
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
            return ( _post_or_put $data.id )
        }
    }

    if ($data.ids | is-empty) {
        # Fetch either single invoice by it's optional id
        # or list of invoices
        return (
            _fetch $data.id {
                    limit: $limit,
                    sortby: $sort_by,
                    sortorder: $sort_order,
                    lastmodified: $last_modified,

                    fromdate: $date_range.from,
                    todate: $date_range.to,

                    yourordernumber: $your_order_number,
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
