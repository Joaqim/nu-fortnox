use ../../utils/url_encode_params.nu
use ../../utils/compact_record.nu

export def main [
    resources: string,
    params: record = {},
    --page (-p): int,
    --id (-i): int,
    --additional-path (-a): string
    ] -> string {
    ({
        scheme: 'https'
        host: $env._FORTNOX_API_HOST,
        path: ($env._FORTNOX_API_ENDPOINT | path join $resources $"($additional_path)" $"($id)" ),
        params: ( url_encode_params ( {...$params, page: $page} | compact_record --remove-empty ))
    } | url join)
}