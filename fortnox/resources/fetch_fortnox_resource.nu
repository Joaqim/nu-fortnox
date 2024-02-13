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
def _get_fortnox_payload_key [resources: string] record<singular: string, plural: string> -> {
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

export def --env main [
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
        --raw, # --raw is mutually exclusive with --brief, --obfuscate and --no-meta
    ] {
    
    (verify_page_range_and_params $page $params)

    if ($dry_run) {
        log info ("Dry-run: GET @ " + (create_fortnox_resource_url $"($resources)" $params --page=(-100) -a $additional_path -i $id) | str replace "%2D100" $"($page.0)..($page.99? | default ($page| to nuon | split row ".." | last ))")
        return
    }

    ratelimit_sleep
    mut $result = []
    let $cache_key = $"($resources)_(url_encode_params {...$params, page: ( $page | to nuon ), add: $additional_path, id: $id})"

    if $env._FORTNOX_USE_CACHE and not $no_cache {
        let $cached_result = (cache load_from_file $cache_key)
        if $cached_result != null {
            $result = $cached_result
        }
    }

    mut meta_information = {}

    if ($result | is-empty) {
        for $current_page: int in $page {
            let $url: string = (create_fortnox_resource_url $"($resources)" $params --page $current_page -a $additional_path -i $id)

            let $resource: any = (fortnox_request GET $url)

            # If there is no MetaInformation, assume single resource in total with no pagination needed.
            if (($resource.MetaInformation? | describe) != 'record') {
                $result = [$resource]
                break
            }

            if ($meta_information | is-empty) {
                $meta_information = $resource.MetaInformation
            }

            $result = ($result | append ($resource | reject MetaInformation ))

            if $current_page >= $meta_information.@TotalPages {
                break;
            }
        }

        if $env._FORTNOX_USE_CACHE and not $no_cache {
            cache save_to_file $cache_key $result
        }
    }

    let resource_key = (_get_fortnox_payload_key $resources)

    if ($raw) {
        if ($meta_information | is-empty ) {
            return $result.0
        }
        return { $resource_key.plural: [...$result], MetaInformation: $meta_information }
    }

    if not ($meta_information | is-empty) {
        if ($no_meta) {
            $result = ($result | reject MetaInformation)
        } else {
            # Move MetaInformation record to the end of the response body
            $result = ($result | move MetaInformation --after $resource_key.plural)
        }
    }

    $result = ($result | flatten --all)

    def make_brief [] -> record {
        $in | compact_record --remove-empty
    }

    (match [$obfuscate $brief] {
        [true false] => ($result | each { obfuscate_fortnox_resource $resources } )
        [false true] => ($result | reject @url | each { make_brief } )
        [true true] => (
            $result 
            | reject @url
            | each {
                make_brief | obfuscate_fortnox_resource $resources 
            }
        )
        _ => ($result)
    })
}
