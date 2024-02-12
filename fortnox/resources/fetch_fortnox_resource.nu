use ../../utils/ratelimit_sleep.nu
use ../auth/get_auth_headers.nu
use std log

# Returns the body of the Fortnox response as json
def --env _request [
    method: string,
    url: string,
    --body: any = {},
    --access-token: string = "",
    --current-retry-count: int = 0
    ] -> record {
    ratelimit_sleep


    mut $headers = (get_auth_headers --access-token $access_token)

    return (
        match ($method | str upcase) {
            GET => {http get $url -H $headers -e -f}
            POST => {http post $url $body -H $headers -e -f}
            _ => {
                error make {
                    msg: "Unexpected method",
                    label: {
                        msg: 'Expected "GET", "POST", ...'
                        span: (metadata $method).span
                    }
                }
            }
        }
        | match $in.status {
        401 => {
            # Handles 'Too many requests'

            # NOTE: Do some testing to see if this is actually better than just using a static duration for 'sleep':
            ratelimit_sleep

            # Prevents infinite loop, exits after max retries:
            if $current_retry_count > ($env._FORTNOX_MAX_RETRIES_COUNT? | default 5) {
                error make {
                    msg: $"Request failed after ($current_retry_count) tries - ($in.body.error)",
                    label: {
                        text: $in.body.error_description,
                        span: (metadata $url).span
                    }
                }
            }
            (_request $method $url --body $body --current-retry-count ($current_retry_count + 1))
        }
        200 => {
            $in.body
        }
        201 => {
            $in.body
        }
        400 => {
            error make {
                msg: $"($in.status) - ($in.body.ErrorInformation.message)"
                label: {
                    text: $"'($method | str upcase )' @ '($url)'",
                    span: (metadata $url).span
                }
            }
        }
        401 => {
            error make {
                msg: $"($in.status) - ($in.body.ErrorInformation.message)"
                label: {
                    text: $"'($method | str upcase )' @ '($url)'",
                    span: (metadata $url).span
                }
            }
        }
        _ => {
            error make {
                msg: $"($in.status) - ($in.body | into string )",
                label: {
                    text: $"'($method | str upcase )' @ '($url)'",
                    span: (metadata $url).span
                }
            }
        }
    })
}

use ./obfuscate_fortnox_resource.nu
use ./create_fortnox_resource_url.nu
use ../../utils/url_encode_params.nu
use ../../utils/compact_record.nu
use ../../utils/cache/

export def --env main [
        resources: string,
        params?: record = {},
        --page: range = 1..1,
        --id: int,
        --additional-path (-a): string = "",
        --brief,
        --no-cache,
        --obfuscate,
        --no-meta
    if ($dry_run) {
        log info ("Dry-run: GET: " + (create_fortnox_resource_url $"($resources)" $params --page=(-100) -a $additional_path -i $id) | str replace "%2D100" $"($page.0)..($page.99? | default 100)")
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

    if ($result | is-empty) {
        for $current_page: int in $page {
            let $url: string = (create_fortnox_resource_url $"($resources)" $params --page $current_page -a $additional_path -i $id)

            let $resource: any = (_request GET $url)

            # If there is no MetaInformation, assume single resource in total with no pagination needed.
            if (($resource.MetaInformation? | describe) != 'record') {
                $result = [$resource]
                break
            }

            $result = ($result | append ($resource | reject MetaInformation ))

            if $current_page >= $resource.MetaInformation.@TotalPages {
                break;
            }
        }

        if $env._FORTNOX_USE_CACHE and not $no_cache {
            cache save_to_file $cache_key $result
        }
    }

    if not ($result.0.MetaInformation? | is-empty) {
        if ($no_meta) {
            $result = ($result | reject MetaInformation)
        } else {
            let $fortnox_resource_payload = $result.0 | reject MetaInformation
            let $fortnox_resource_payload_key = $fortnox_resource_payload | columns | first
            # Move MetaInformation columns to the end of the table
            $result = ($result | move MetaInformation --after $fortnox_resource_payload_key)
        }
    }
    $result = ($result | flatten --all)

    (match [$obfuscate $brief] {
        [true false] => ($result | each { obfuscate_fortnox_resource $resources } )
        [false true] => ($result | reject @url | each { compact_record --remove-empty } )
        [true true] => (
            $result 
            | reject @url
            | each {
                compact_record --remove-empty | obfuscate_fortnox_resource $resources 
            }
        )
        _ => ($result)
    })
}
