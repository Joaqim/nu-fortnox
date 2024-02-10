use ../dependencies/nu-ratelimit/ ratelimit sleep_as_needed

export def --env main [] -> {
    sleep_as_needed --requests-per-interval ($env._FORTNOX_MAX_REQUESTS_PER_PERIOD | into int) --interval-seconds ($env._FORTNOX_INTERVAL_OF_MAX_REQUESTS_IN_SECONDS | into int)
}