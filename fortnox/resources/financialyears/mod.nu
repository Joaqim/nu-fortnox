use ../utils/fortnox_resource_url.nu
use ../fortnox_request.nu


export def main [
    --financial-year-id: int
    --filter-by-date: string # NOTE: Doesn't affect result from Fortnox API if financial year id is provided
    --no-cache
] {

    let $url: string = (fortnox_resource_url 'financialyears' {date: $filter_by_date} --id=($financial_year_id))
    (fortnox_request 'get' $url --no-cache=($no_cache))
}
