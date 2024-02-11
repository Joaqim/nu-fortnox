
export def main [
        credentials: record<accessToken: string, expiresAt: string>
    ] -> bool {
    (($credentials.accessToken? | is-empty) or (date now) < ($credentials.expiresAt | into datetime))
}