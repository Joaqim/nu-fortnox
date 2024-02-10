
export-env {
    source .env.nu

    if XDG_CONFIG_DIR in $env and ($env.XDG_CONFIG_DIR | path exists)  {
        $env._FORTNOX_CONF_DIR = ($env.XDG_CONFIG_DIR | path join fortnox)
    } else {
        $env._FORTNOX_CONF_DIR = ($env.HOME | path join .fortnox)
    }
    if XDG_DATA_HOME in $env and ($env.XDG_DATA_HOME | path exists)  {
        $env._FORTNOX_DATA_DIR = ($env.XDG_DATA_HOME | path join fortnox)
    } else {
        $env._FORTNOX_DATA_DIR = $env._FORTNOX_CONF_DIR
    }

    if not _FORTNOX_USE_CACHE in $env {
        $env._FORTNOX_USE_CACHE = false
    }

    if $env._FORTNOX_USE_CACHE {
        $env._FORTNOX_CACHE_DIR = ($env._FORTNOX_DATA_DIR | path join "cache")
        $env._FORTNOX_CACHE_VALID_DURATION = ('30min' | into duration)

        mkdir $env._FORTNOX_CACHE_DIR

        # Cleanup existing cache
        (ls $env._FORTNOX_CACHE_DIR | where {$in.modified - $env._FORTNOX_CACHE_VALID_DURATION >= (date now)} | each { rm $in.name } )
    }

    if not _FORTNOX_DB_CLIENT in $env {
        $env._FORTNOX_DB_CLIENT = "mongodb"
    }

    $env.QUEUE_LIST = []

    $env._FORTNOX_API_HOST = "api.fortnox.se"
    $env._FORTNOX_API_ENDPOINT = "/3/"
    $env._FORTNOX_TOKEN_API_URL = "https://apps.fortnox.se/oauth-v1/token"

    # The limit is 300 requests per minute per client-id and tenant.
    # The rate limit is based on a sliding window algorithm with a period of 5 seconds,
    # so the actual limit is 25 requests per 5 seconds.

    # Any over-usage (burst) during a period will mean that the rate limit kicks in until enough
    # time has passed to make the average 25 requests per period again.

    $env._FORTNOX_MAX_REQUESTS_PER_PERIOD = 25
    $env._FORTNOX_INTERVAL_OF_MAX_REQUESTS_IN_SECONDS = 5
    $env._FORTNOX_MAX_RETRIES_COUNT = 5
}