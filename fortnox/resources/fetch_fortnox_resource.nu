use std log

use ./utils/obfuscate_fortnox_resource.nu
use ./utils/fortnox_resource_url.nu
use ./utils/verify_pagination_params.nu
use ./utils/fortnox_payload_keys.nu
use ../../utils/url_encode_params.nu
use ../../utils/compact_record.nu
use ../../utils/cache/
use ../../utils/progress_bar.nu


use ./fortnox_request.nu

export def main [
        resources: string,
        opts: record<
            pages: range
            additional_path: string
            brief: bool
            no_cache: bool
            obfuscate: bool
            with_pagination: bool
            dry_run: bool
            raw: bool
        >
        params?: record = {},
    ] {

    if ($opts.dry_run) {
        let $url = (
            (fortnox_resource_url $"($resources)" $params
                --page=(123)
                -a $opts.additional_path
            )
            # Here we replace placeholder page param '123' with values from our range: <min>..<max>
            | str replace "123" (
                $"($opts.pages | to nuon)"
            )
        )
        log info ($"Dry-run: 'GET' @ ($url)")
        let $resource_keys = (fortnox_payload_keys $resources)
        return [{ $resource_keys.plural: [{'@url': $url}], MetaInformation: {'@TotalPages': 1, '@CurrentPage': 1, '@TotalResources': 1} }]
    }


    (verify_pagination_params $opts.pages $params)

    def _fetch_page [$page_nr: int]: int -> any {
        let $current_page_url: string = (fortnox_resource_url $resources --page=($page_nr) $params -a $opts.additional_path)
        (fortnox_request
            'get'
            $current_page_url
            --no-cache=($opts.no_cache)
        )
    }

    let $first_page = ($opts.pages | math min)
    let $last_page = ($opts.pages | math max)

    mut $result: list<any> = (_fetch_page $first_page)

    # Get previous pagination from last result
    if ($result | describe) !~ ^list {
        $result = [$result]
    }

    let $current_page = (($result | last).MetaInformation?.@CurrentPage | default $first_page | into int)
    let $total_pages = (($result | last).MetaInformation?.@TotalPages | default $last_page | into int)

    if ($current_page < $total_pages) {

        const $FORTNOX_PAGINATION_LIMIT = 500;
        let $pages_indices = (
            ($current_page)..(
                [
                    $total_pages
                    $last_page
                    $FORTNOX_PAGINATION_LIMIT
                ] | math min
            )
        )

        $result = (
            $result | append
                (progress_bar $pages_indices --start-offset=($current_page) {|$current_page_nr|
                    (_fetch_page $current_page_nr)
                }
            )
        )
    }

    if ($env._FORTNOX_USE_CACHE) and not ($opts.no_cache) {
        let $cache_key: string = (fortnox_resource_url $resources --page=($first_page) $params -a $opts.additional_path)
        cache save_to_file $cache_key $result
    }


    if ($result | describe) =~ ^list {
        if ($result | length) == 1 {
            $result = $result.0
        }
    }

    if not $opts.raw and not ($opts.with_pagination) {
        return ($result | reject MetaInformation? --ignore-errors | flatten -a)
    }

    return $result
}
