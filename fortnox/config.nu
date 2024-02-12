export-env {
    $env._FORTNOX_USE_CACHE = true # default: false
    $env._FORTNOX_CACHE_VALID_DURATION = 5min # default: 5min

    $env._FORTNOX_DB_CREDENTIALS_QUERY = '{"provider": "fortnox"}'
    $env._FORTNOX_DB_CLIENT = "mongodb"
}