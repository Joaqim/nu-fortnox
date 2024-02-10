use ./get_access_token.nu

export def main [
    --access-token: string
    ] -> record<Authorization: string, "Content-Type": string> {
    ({
        Authorization: $"Bearer (if ($access_token | default "" | is-empty) { (get_access_token) } else { ($access_token) })",
        "Content-Type": "application/json",
    })
}
