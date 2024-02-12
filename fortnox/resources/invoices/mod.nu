use ../bool_flags_to_filter.nu
use ../fetch_fortnox_resource.nu
use ../../../utils/ratelimit_sleep.nu
use ../../../utils/get_daterange_from_params.nu

# Returns an empty list if no resources found
export def --env main [
    invoice_number? : int # Get a known invoice by its invoice number
    --filter-by-your-order-number (-f): string, # Filter by 'YourOrderNumber'
    --customer-name (-c): string, # Filter by 'CustomerName'

    --last-modified (-m): datetime, # Filter by last modification date for Fortnox documents

    --from-date (-s): string, # Fortnox 'fromdate' param, expects 'YYYY-M-D'
    --to-date (-e): string, # Fortnox 'todate' param, expects 'YYYY-M-D'
    --date (-d): string, # Sets both 'fromdate' and 'todate' to this value

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

    --brief (-b), # Remove empty values
    --obfuscate (-O), # Remove Customer's info, but not customer's country
    --no-meta (-N), # Remove Fortnox 'MetaInformation' for pagination: @TotalResource, @TotalPages, @CurrentPage
    --limit (-l): int = 100, # Limit how many resources to fetch, expects integer [1-100]
    --page (-p): range = 1..1, # If range is higher than 1..1, limit must be set to 100
    --sort-by (-s): string = 'invoicedate', # Set 'sortby' param for Fortnox request
    --sort-order (-s): string = 'descending', # Set 'sortorder' param for Fortnox Request, expects 'ascending' or 'descending'
] -> list<record> {
    let $filter = (
        bool_flags_to_filter {
            cancelled: $filter_by_cancelled
            unbooked: $filter_by_unbooked
            fullypaid: $filter_by_fullypaid
            unpaid: $filter_by_unpaid
            unpaidoverdue: $filter_by_unpaidoverdue
        }
    )

    mut $date_range = {
        from: ($from_date | default $date)
        to: (
            $to_date 
            | default $date 
            | default (
                date now | format date "%Y-%m-%d"
            )
        )
    }
    
    if ($from_date | is-empty) and ($to_date | is-empty) {
        if ([$for_quarter $for_year $for_month $for_day] | any { not ( $in | is-empty ) }) {
            $date_range = (get_daterange_from_params --for-year $for_year --for-month $for_month --for-day $for_day --for-quarter $for_quarter --to-date-offset "1day")
        }
    }

    (fetch_fortnox_resource "invoices" --id $invoice_number --page $page --brief=($brief) --obfuscate=($obfuscate) --no-cache=($no_cache) --no-meta=($no_meta) {
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
