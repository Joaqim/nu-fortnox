use ../bool_flags_to_filter.nu
use ../fetch_fortnox_resource.nu
use ../../../utils/ratelimit_sleep.nu
use ../../../utils/get_daterange_from_params.nu


export def --env main [
    --invoice-number (-i): int, # Fetch specific invoice, returns list<record> 
    --filter-by-your-order-number (-f): string, # Filter by 'YourOrderNumber'
    --customer-name (-c): string, # Filter by 'CustomerName'

    --last-modified (-m): datetime, # Filter by last modification date for Fortnox documents

    --from-date (-s): string, # Fortnox 'fromdate' param, expects 'YYYY-M-D'
    --to-date (-e): string, # Fortnox 'fromdate' param, expects 'YYYY-M-D'

    --for-year (-Y): int, # Specify from/to date range by year, expects integer above 1970
    --for-quarter (-Q): int, # Specify from/to date range by quarter, expects integer [1-4]
    --for-month (-M): int, # Specify from/to date range by month, expects integer [1-12]
    --for-day (-D): int, # Specify from/to date range by day, expects integer [1-32]

    --full-date: string, # Specify specific date WIP

    --filter-by-unbooked, # Filter by 'unbooked' status in Fortnox
    --filter-by-cancelled, # Filter by 'cancelled' status in Fortnox
    --filter-by-fullypaid, # Filter by 'fullypaid' status in Fortnox
    --filter-by-unpaid, # Filter by 'unpaid' status in Fortnox
    --filter-by-unpaidoverdue, # Filter by 'unpaidoverdue' status in Fortnox

    --filter-override (-F): string, # Use specified filter param in Fortnox request

    --no-cache, # Don't use cache for request. NOTE: received resource doesn't overwrite existing cache

    --brief (-b), # Remove empty values
    --obfuscate (-O), # Remove Customer's info, but not customer's country
    --limit (-l): int = 100, # Limit how many resources to fetch, expects integer [1-100]
    --page (-p): range = 1..1, # If range is higher than 1..1, limit must be set to 100
    --sort-by (-s): string = 'invoicedate', # Set 'sortby' param for Fortnox request
    --sort-order (-s): string = 'descending', # Set 'sortorder' param for Fortnox Request, expects 'ascending' or 'descending'
] -> list<record> {
    let $filter = (
        bool_flags_to_filter --filter-override $filter_override {
            cancelled: $filter_by_cancelled
            unbooked: $filter_by_unbooked
            fullypaid: $filter_by_fullypaid
            unpaid: $filter_by_unpaid
            unpaidoverdue: $filter_by_unpaidoverdue
        }
    )

    mut $date_range = {
        from: $from_date
        to: $to_date
    }
    
    if ($from_date | is-empty) and ($to_date | is-empty) {
        if not ($full_date | is-empty) {
            $date_range = (get_daterange_from_params --for-year $for_year --for-month $for_month --for-day $for_day --for-quarter $for_quarter)
        } else {
            $date_range = (
                from: ($full_date | into datetime)
                to: ($full_date | into datetime)
            )
        }
    } else {
        # Debug:
        print ($date_range.from | format date "%Y-%m-%dT%H:%M:%S.%9f")
        print ($date_range.to | format date "%Y-%m-%dT%H:%M:%S.%9f")
    }

    (fetch_fortnox_resource "invoices" --id $invoice_number --page $page --brief=($brief) --obfuscate=($obfuscate) --no-cache=($no_cache) {
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
