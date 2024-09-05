use ../utils/bool_flags_to_filter.nu
use ../utils/parse_actions_from_params.nu
use ../utils/fortnox_resource_url.nu
use ../utils/parse_ids_and_body_from_input.nu
use ../utils/verify_filter_params.nu
use ../../../utils/ratelimit_sleep.nu
use ../../../utils/get_daterange_from_params.nu
use ../../../utils/compact_record.nu
use ../../../utils/progress_bar.nu

use ../fetch_fortnox_resource.nu
use ../fortnox_request.nu


export use ./actions/ *

use std log

def _fortnox_invoice_number__completion [$context: string] -> list<int> {
    try {
        return (fetch_fortnox_resource "invoices" {} {limit: 10, sortby: 'documentnumber', sortorder: 'descending', no_cache: true } | get Invoices.DocumentNumber)
    }
    return []
}

const $filter_completions = [cancelled fullypaid unpaid unpaidoverdue unbooked]
def _fortnox_invoices_filter__completion [$context: string] -> list<string> {
    ($filter_completions)
}

const $sort_by_completions = ["customername" "customernumber" "documentnumber" "invoicedate" "ocr" "total"]
def _fortnox_invoices_sort_by__completion [$context: string] -> list<string> {
    ($sort_by_completions)
}

def _fortnox_invoices_sort_order__completion [$context: string] -> list<string> {
    (['ascending', 'descending'])
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
            Now
        ]
    )
}

const $FORTNOX_RESOURCES = 'invoices'

# NOTE: fetching invoices by list of Document numbers doesn't use cache for list larger than 1

# Returns an empty list if no resources was found
export def main [
    --invoice-number (-i): int@_fortnox_invoice_number__completion # Get a known invoice by its invoice number
    --filter (-F): string@_fortnox_invoices_filter__completion, # Filters for invoices:  'unbooked', 'cancelled', 'fullypaid', 'unpaid', 'unpaidoverdue'

    --limit (-l): int = 100, # Limit how many resources to fetch, expects integer [1-100]
    --page (-p): range = 1..1, # If range is higher than 1..1, limit must be set to 100
    --sort-by (-s): string@_fortnox_invoices_sort_by__completion = 'documentnumber', # Set 'sortby' param for Fortnox request
    --sort-order (-s): string@_fortnox_invoices_sort_order__completion = 'descending', # Set 'sortorder' param for Fortnox Request, expects 'ascending' or 'descending'

    --your-order-number (-f): string, # Returns list of Invoice(s) filtered by YourOrderNumber
    --customer-name (-c): string, # Returns list of Invoice(s) filtered by CustomerName
    --last-modified (-m): any, # Returns list of Invoice(s) filtered by last modified date

    --from-date (-s): string, # Fortnox 'fromdate' param, expects 'YYYY-M-D'
    --to-date (-e): string, # Fortnox 'todate' param, expects 'YYYY-M-D, cannot not be used without 'from-date', 'from', 'date' or 'for-[year quarter month day]
    --date (-d): string, # Sets both 'fromdate' and 'todate' to this value, useful if you want a single day. Expects: 'YYYY-M-D'
    --from: string@_datetime_string__completion, # Sets Fortnox 'fromdate' param, expects a readable datetime string, see 'into datetime --list-human'

    --from-final-pay-date: string,
    --to-final-pay-date: string,

    --for-year (-Y): int, # Specify from/to date range by year, expects integer above 1970
    --for-quarter (-Q): int, # Specify from/to date range by quarter, expects integer [1-4]
    --for-month (-M): int, # Specify from/to date range by month, expects integer [1-12]
    --for-day (-D): int, # Specify from/to date range by day, expects integer [1-32]

    --no-cache, # Don't use cached result.
    --dry-run, # Dry run, log the Fortnox API url, returns 'nothing'

    --brief (-b), # Filter out empty values from result
    --obfuscate (-O), # Filter out Confidential information. Does not remove not Country ISO codes
    --with-pagination (-P), # Return result includes Fortnox 'MetaInformation' for pagination: @TotalResource, @TotalPages, @CurrentPage
    --raw, # Returns least modified Fortnox response, --raw is mutually exclusive with --brief, --obfuscate and --with-pagination
] -> record {
    let $date_range = (
        get_daterange_from_params
            --for-year $for_year
            --for-quarter $for_quarter
            --for-month $for_month
            --for-day $for_day
            --date $date
            --from $from
            --from-date $from_date
            --to-date $to_date

            --to-date-precision 1day # Fortnox uses date format: %Y-%m-%d, so the last day in a month would be where a date range (--month) would encompass 01-01 -> 01->31.
            --utc-offset 1 # UTC+1 local Europe/Stockholm time
    )

    def internal_params [] {
        {
            pages: $page
            brief: $brief
            obfuscate: $obfuscate
            no_cache: $no_cache
            with_pagination: $with_pagination
            additional_path: '' # Additional path is used for vouches series, where /3/vouchers/{VoucherSeries}/{VoucherNumber}
            dry_run: $dry_run
            raw: $raw
        }
    }

    def fortnox_params [] {
        {
            limit: $limit,
            sortby: $sort_by,
            sortorder: $sort_order,
            lastmodified: $last_modified,

            fromdate: $date_range.from,
            todate: $date_range.to,

            yourordernumber: $your_order_number,
            filter: $filter
        }
    }

    (fetch_fortnox_resource $FORTNOX_RESOURCES
        (internal_params)
        (fortnox_params)
    )
}

use ./actions/mod.nu *