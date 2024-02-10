use ../../db_client

export def main [
        body: record<access_token: string, refresh_token: string, expires_in: int>
    ] -> string {
    let $expires_at = ((date now) + ($body.expires_in | into duration --unit sec) | to nuon)
    let $entry = ([
            "{"
            $"expiresAt: ISODate\("($expires_at)"\),"
            $'accessToken: "($body.access_token)",'
            $'refreshToken: "($body.refresh_token)"'
            "}"
        ] | str join "")

    db_client update_one 'credentials' $env._FORTNOX_DB_CREDENTIALS_QUERY $entry
    ($body.access_token)
}