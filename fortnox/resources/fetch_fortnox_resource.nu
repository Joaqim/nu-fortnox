use ../../utils/ratelimit_sleep.nu
use ../auth/get_auth_headers.nu

# Returns the body of the Fortnox response as json
def --env _request [
    method: string,
    url: string,
    --body: any = {},
    --access-token: string = "",
    --current-retry-count: int = 0
    ] -> record {
    ratelimit_sleep

    {
        "MetaInformation": {TotalPages: 2, CurrentPage: (url | parse --regex "\\S+page=(\\d+).*" | into int) }
        "Invoices": [{"@Url": $url, "CustomerName": "Confidential", "CustomerEmail": "confidential@mail.com", "EmailInformation": {"EmailTo": "confidential@mail.com"}, "Country": Sverige, "City": Gothenburg, "DeliveryCity": Gothenburg, "DeliveryCountry": Sverige }]
    }

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
            if $current_retry_count > ($env._FORTNOX_MAX_RETRIES_COUNT | default 5) {
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
    ] {
    if $page != 1..1 and $params.limit != 100 {
        error make {
            msg: "Unexpected param value"
            label: {
                text: "Expected '--limit (-l)' to be 100 when fetching more than 1 page '--page (-p)'."
                span: (metadata $params.limit).span
            }
        }
    }
    ratelimit_sleep
    mut $result = []
    let $cache_key = $"($resources)_(url_encode_params {...$params, page: ( $page | first ), add: $additional_path, id: $id})"

    if $env._FORTNOX_USE_CACHE and (not $no_cache) {
        let $cached_result = (cache load_from_file $cache_key)
        if $cached_result != null {
            $result = $cached_result
        }
    }

    if ($result | is-empty) {
        for $current_page: int in $page {
            let $url: string = (create_fortnox_resource_url $"($resources)" $params --page $current_page -a $additional_path -i $id)

            let $resource: any = (_request GET $url)

            if not MetaInformation in $resource {
                $result = [$resource]
                break
            }

            $result = ($result | append ($resource | reject MetaInformation ))

            if $current_page >= $resource.MetaInformation.@TotalPages {
                break;
            }
        }

        if $env._FORTNOX_USE_CACHE {
            cache save_to_file $cache_key $result
        }
    }

    $result = ($result | flatten --all)

    (match [$obfuscate $brief] {
        [true false] => ($result | each { obfuscate_fortnox_resource $resources $in })
        [false true] => ($result | each { compact_record $in --remove-empty })
        [true true] => (
            $result
            | each { compact_record $in --remove-empty }
            | each { obfuscate_fortnox_resource $resources $in }
        )
        _ => ($result)
    })
}
