use ../bool_flags_to_filter.nu
use ../parse_actions_from_params.nu
use ../fetch_fortnox_resource.nu
use ../../../utils/ratelimit_sleep.nu
use ../../../utils/get_daterange_from_params.nu
use ../../../utils/compact_record.nu
use ../create_fortnox_resource_url.nu
use ../fortnox_request.nu

use std log

# Returns an empty list if no resources found
export def main [
    invoice_number? : int # Get a known invoice by its invoice number
    --put-action: string # Perform PUT action for invoice number: 'update', 'bookkeep' 'cancel', 'credit', 'externalprint', 'warehouseready'
    --post-action: string # Perform POST action for invoice number: 'create'
    --get-action: string # Perform GET action for invoice number: 'print', 'email', 'printreminder', 'preview', 'eprint', 'einvoice' 
    --body: any # Request body to POST or PUT to Fortnox API for actions: 'create' or 'update'
    --filter-by-your-order-number (-f): string, # Filter by 'YourOrderNumber'
    --customer-name (-c): string, # Filter by 'CustomerName'

    --last-modified (-m): datetime, # Filter by last modification date for Fortnox documents

    --from-date (-s): string, # Fortnox 'fromdate' param, expects 'YYYY-M-D'
    --to-date (-e): string, # Fortnox 'todate' param, expects 'YYYY-M-D, cannot not be used without 'from-date', 'from', 'date' or 'for-[year quarter month day]
    --date (-d): string, # Sets both 'fromdate' and 'todate' to this value
    --from: string, # From date in readable duration string, see 'into datetime -n'

    --for-year (-Y): int, # Specify from/to date range by year, expects integer above 1970
    --for-quarter (-Q): int, # Specify from/to date range by quarter, expects integer [1-4]
    --for-month (-M): int, # Specify from/to date range by month, expects integer [1-12]
    --for-day (-D): int, # Specify from/to date range by day, expects integer [1-32]

    --filter-by-unbooked, # Filter by 'unbooked' status in Fortnox
    --filter-by-cancelled, # Filter by 'cancelled' status in Fortnox
    --filter-by-fullypaid, # Filter by 'fullypaid' status in Fortnox
    --filter-by-unpaid, # Filter by 'unpaid' status in Fortnox
    --filter-by-unpaidoverdue, # Filter by 'unpaidoverdue' status in Fortnox

    --no-cache, # Don't use cache for request. NOTE: received resource doesn't overwrite existing cache
    --dry-run, # Dry run, log the Fortnox API url, returns 'nothing'

    --brief (-b), # Remove empty values
    --obfuscate (-O), # Remove Customer's info, but not customer's country
    --no-meta (-N), # Remove Fortnox 'MetaInformation' for pagination: @TotalResource, @TotalPages, @CurrentPage
    --raw, # Returns least modified Fortnox response, --raw is mutually exclusive with --brief, --obfuscate and --no-meta

    --limit (-l): int = 100, # Limit how many resources to fetch, expects integer [1-100]
    --page (-p): range = 1..1, # If range is higher than 1..1, limit must be set to 100
    --sort-by (-s): string = 'invoicedate', # Set 'sortby' param for Fortnox request
    --sort-order (-s): string = 'descending', # Set 'sortorder' param for Fortnox Request, expects 'ascending' or 'descending'
] -> list<record> {

    let action = (parse_actions_from_params "invoices" {put: $put_action, post: $post_action, get: $get_action} --id $invoice_number --body $body)

    if not ($action | compact_record | is-empty) {
        let $url = (create_fortnox_resource_url "invoices" --id $invoice_number --action $action.action )
        if ($dry_run) {
            log info $"Dry-run: ($action.method) @ ($url) ($body | to nuon)"
            return
        }
        return ( fortnox_request $action.method $url --body $body)
    }

    let $filter = (
        bool_flags_to_filter {
            cancelled: $filter_by_cancelled
            unbooked: $filter_by_unbooked
            fullypaid: $filter_by_fullypaid
            unpaid: $filter_by_unpaid
            unpaidoverdue: $filter_by_unpaidoverdue
        }
    )

    let $date_range = (
        get_daterange_from_params 
            --for-year $for_year
            --for-quarter $for_quarter
            --for-month $for_month
            --for-day $for_day
            --date $date
            --from-date $from_date
            --to-date $to_date
            --to-date-precision 1day # Fortnox uses date format: %Y-%m-%d, so the last day in a month would be where a date range (-M) would end at 01-01 -> 01->31.
            --from $from
    )

    (fetch_fortnox_resource "invoices" 
            --id $invoice_number
            --page $page 
            --brief=($brief)
            --obfuscate=($obfuscate)
            --no-cache=($no_cache)
            --no-meta=($no_meta)
            --dry-run=($dry_run)
            --raw=($raw) 
            {
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
}
