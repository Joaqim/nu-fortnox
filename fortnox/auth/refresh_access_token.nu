use ../../utils/ratelimit_sleep.nu
use ./update_remote_credentials.nu

export def main [
    client_identity: string,
    client_secret: string,
    refresh_token: string
    ] -> string {
    ratelimit_sleep

    let body = {
         grant_type: "refresh_token",
         refresh_token: $refresh_token
    }

    let $url: string = $env._FORTNOX_TOKEN_API_URL

    let response: record<body: record, status: int> = (
        http post $url --content-type "application/x-www-form-urlencoded" $body -u $client_identity -p $client_secret -e -f
    )


    (match $response.status {
        200 => ( update_remote_credentials $response.body )
        400 => {
            let $token_error_body = ($response.body | from json)
            error make {
                msg: $"($response.status) - ($token_error_body.error)",
                label: {
                    text: $token_error_body.error_description,
                    span: (
                        match $token_error_body.error_description {
                            "Invalid refresh token" => (metadata $body.refresh_token).span
                            _ => (metadata $body).span
                        }
                    )
                }
            }
        }
        _ => { error make {
                    msg: $response.body.error,
                    label: {
                        text: $response.body.error_description,
                        span: (metadata $url).span
                    }
                }
            }
        }
    )
}

