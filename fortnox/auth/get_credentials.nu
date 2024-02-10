use ../../db_client

export def main [
    ] -> record<clientIdentity: string, clientSecret: string, accessToken: string, expiresAt: string> {
    (db_client find_one 'credentials' $env._FORTNOX_DB_CREDENTIALS_QUERY)
}

