use ./get_credentials.nu
use ./has_valid_token.nu
use ./refresh_access_token.nu

export def main [] -> string {
    let credentials = (get_credentials)

    if not (has_valid_token $credentials) {
        return (refresh_access_token $credentials.clientIdentity $credentials.clientSecret $credentials.refreshToken)
    }
    ($credentials.accessToken)
}

