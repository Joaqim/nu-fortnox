use ../db_client/

export def fetch_remote_credentials [
    ] -> record<clientIdentity: string, clientSecret: string, accessToken: string, expiresAt: string> {
    (db_client fetch_credentials)
}

export def update_remote_credentials [
        body: record<access_token: string, refresh_token: string, expires_in: int>
    ] -> string {
    (db_client update_credentials
        --access-token $body.access_token
        --refresh-token $body.refresh_token
        --expires-in $body.expires_in
    )
    ($body.access_token)
}

export def refresh_access_token [
    client_identity: string,
    client_secret: string,
    refresh_token: string
    ] -> string {

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
            # TODO: Handle: { token_error_body.error == 'invalid_grant' }
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

export def has_valid_token [
        credentials: record<accessToken: string, expiresAt: string>
    ] -> bool {
    ((not ($credentials.accessToken? | is-empty)) and (date now) < ($credentials.expiresAt | into datetime))
}

export def get_access_token [] -> string {
    let credentials = (fetch_remote_credentials)

    if not (has_valid_token $credentials) {
        return (refresh_access_token $credentials.clientIdentity $credentials.clientSecret $credentials.refreshToken)
    }
    ($credentials.accessToken)
}

export def get_auth_headers [
    --access-token: string = ""
    ] -> record<Authorization: string, "Content-Type": string> {
    ({
        Authorization: $"Bearer (if ($access_token | is-empty) { (get_access_token) } else { ($access_token) })",
    })
}






