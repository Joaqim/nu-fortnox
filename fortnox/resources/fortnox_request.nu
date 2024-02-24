use ../../auth_client/ *
use ../../utils/ratelimit_sleep.nu

# Returns the body of the Fortnox response as json
export def --env main [
    method: string,
    url: string,
    --body: any,
    --access-token: string = "",
    --current-retry-count: int = 0
    ] -> any {
    ratelimit_sleep


    mut $headers = (get_auth_headers --access-token $access_token)

    return (
        match ($method | str upcase) {
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
            (request $method $url --body $body --current-retry-count ($current_retry_count + 1))
        }
        200 => {
            $in.body
        }
        201 => {
            $in.body
        }
        400 => {
            error make {
                msg: $"($in.status) - ($in.body.ErrorInformation?.message?)"
                label: {
                    text: $"'($method | str upcase )' @ '($url)'",
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
    })
}

