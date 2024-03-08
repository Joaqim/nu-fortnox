use ../../auth_client/ *
use ../../utils/ratelimit_sleep.nu
use ../../utils/cache/

# Moved from main to allow recursive retries when 401 is returned from Fortnox API
def _request [
    method: string,
    url: string,
    --body: any,
    --access-token: string = "",
    --current-retry-count: int = 0
    ] {
        let $headers = (get_auth_headers --access-token $access_token)
        (match ($method | str upcase) {
            GET => {http get $url -H $headers -e -f}
            POST => {
                    http post --content-type application/json $url ($body | default '') -H $headers -e -f
            }
            PUT => {
                    http put --content-type application/json $url ($body | default '') -H $headers -e -f
            }
            _ => {
                error make {
                    msg: "Unexpected method",
                    label: {
                        msg: $"Expected 'get', 'post', or 'put', received: '($method)'"
                        span: (metadata $method).span
                    }
                }
            }
        } | match $in.status {
            401 => { # 'Too many requests'

                # Prevents infinite loop, exits after reaching max retries:
                if $current_retry_count > ($env._FORTNOX_MAX_RETRIES_COUNT? | default 5) {
                    error make {
                        msg: $"Request failed after ($current_retry_count) tries - ($in.body.error)",
                        label: {
                            text: $in.body.error_description,
                            span: (metadata $url).span
                        }
                    }
                }

                # TODO: Do some testing to see if this is actually better than just using a static duration for 'sleep':
                ratelimit_sleep
                (_request $method $url --body $body --current-retry-count ($current_retry_count + 1))
            }
            200 => {
                $in.body
            }
            201 => {
                $in.body
            }
            400 => {
                let $body = $in.body
                let $fortnox_message = $body.ErrorInformation?.message?
                if ($fortnox_message == "Angiven sida hittades ej (24).") {
                    return null
                }
                error make {
                    msg: $"($in.status) - ($fortnox_message | default ($body | to json -r))"
                    label: {
                        text: $"'($method | str upcase )' @ '($url | url decode )'",
                        span: (metadata $url).span
                    }
                }
            }
            401 => {
                error make {
                    msg: $"($in.status) - ($in.body.ErrorInformation?.message?)"
                    label: {
                        text: $"'($method | str upcase )' @ '($url)'",
                        span: (metadata $url).span
                    }
                }
            }
            _ => {
                error make {
                    msg: $"($in.status) - ($in.body | to nuon )",
                    label: {
                        text: $"'($method | str upcase )' @ '($url)'",
                        span: (metadata $url).span
                    }
                }
            }
        }
    )
}


# Returns the body of the Fortnox response as json
export def --env main [
    method: string,
    url: string,
    --body: any,
    --access-token: string = "",
    --current-retry-count: int = 0
    --optional-cache-key: any = null
    --no-cache
    ] -> any {
    let fn = { || _request $method $url --body $body --access-token $access_token }

    if $env._FORTNOX_USE_CACHE and (not $no_cache) {
        return (cache function_call ($optional_cache_key | default $url) $fn)
    }

    (do $fn)
}
