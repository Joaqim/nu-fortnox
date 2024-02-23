use ../../utils/ratelimit_sleep.nu
use ../auth/get_auth_headers.nu
use std log

use ./obfuscate_fortnox_resource.nu
use ./create_fortnox_resource_url.nu
use ./fortnox_request.nu
use ../../utils/url_encode_params.nu
use ../../utils/compact_record.nu
use ../../utils/cache/
use ../../utils/verify_page_range_and_params.nu

# 'invoices' -> [Invoice, Invoices], 'vouchers' -> [Voucher, Vouchers], etc...
def _get_fortnox_payload_key [resources: string] record<singular: string, plural: string> {
    (match ($resources) {
        "invoices" => {{singular: 'Invoice', plural: 'Invoices'}}
        _ => {
            error make {
                msg: "Unknown fortnox resource"
                label: {
                    text: $"Tried to find Fortnox payload key for ($resources)"
                    span: (metadata $resources).span
                }
            }
        }
    })
}

export def main [
        resources: string,
        params?: record = {},
        --page: range = 1..1,
        --id: int,
        --additional-path (-a): string = "",
        --brief,
        --no-cache,
        --obfuscate,
        --no-meta,
        --dry-run,
        --raw, # TODO: --raw should be probably be mutually exclusive with --brief, --obfuscate and --no-meta
    ] {

    (verify_page_range_and_params $page $params)

    if ($dry_run) {
        log info ("Dry-run: GET @ " + (create_fortnox_resource_url $"($resources)" $params --page=(-100) -a $additional_path -i $id) | str replace "%2D100" $"($page.0)..($page.99? | default ($page| to nuon | split row ".." | last ))")
        return
    }

    ratelimit_sleep
    let $resource_key : record<singular: string, plural: string> = (_get_fortnox_payload_key $resources)
    mut $result = {}
    let $cache_key = $"($resources)_(url_encode_params {...$params, page: ( $page | to nuon ), add: $additional_path, id: $id})"

    if $env._FORTNOX_USE_CACHE and (not $no_cache) {
        let $cached_result = (cache load_from_file $cache_key)
        if $cached_result != null {
            $result = $cached_result
        }
    }

    mut $resource_list = []
    mut $meta_information = {}
    if ($result | is-empty) {
        for $current_page in $page {
            let $url: string = (create_fortnox_resource_url $"($resources)" $params --page $current_page -a $additional_path -i $id)

            let $fortnox_payload: any = (fortnox_request GET $url)

            # If there is no MetaInformation, assume single resource with no pagination needed.
            if ($fortnox_payload.MetaInformation? | is-empty) {
                $result = $fortnox_payload
                break
            }

            $resource_list = ($resource_list | append ($fortnox_payload | reject MetaInformation | flatten --all ))

            if $current_page >= ($fortnox_payload.MetaInformation.@TotalPages | into int) {
                $meta_information = $fortnox_payload.MetaInformation
                break;
            } else if not (($current_page + 2) in $page) {
                $meta_information = $fortnox_payload.MetaInformation
            }
        }

        if ($result | is-empty) {
            $result = { $resource_key.plural: $resource_list, MetaInformation: $meta_information }
        }

        if $env._FORTNOX_USE_CACHE {
            cache save_to_file $cache_key $result
        }
    }


    if ($raw) {
        return $result
    }

    if ($no_meta) {
        $result = ($result | reject --ignore-errors MetaInformation)
    } else if not ($result.MetaInformation? | is-empty) {
        # Move MetaInformation record to the end of the response body
        $result = ($result | move MetaInformation --after $resource_key.plural)
    }

    def make_brief [] -> record {
        $in | compact_record --remove-empty | reject --ignore-errors @url
    }

    (match [$obfuscate $brief] {
        [true false] => ($result | reject MetaInformation? | flatten | each { obfuscate_fortnox_resource } | flatten )
        [false true] => ($result | reject MetaInformation? | flatten | each { make_brief } | flatten )
        [true true] => (
            $result
            | reject MetaInformation?
            | flatten
            | each {
                make_brief | obfuscate_fortnox_resource
            } | flatten
        )
        _ => ($result)
    })
}
