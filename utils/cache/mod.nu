use std log

def _create_hash_file_name [key: string] {
    ($key | hash md5 | str substring 0..31)
}

export def load_from_file [key: string, --expiration: duration] -> {
    let $cache_file = ($env._FORTNOX_CACHE_DIR | path join (_create_hash_file_name $key ))
    if not ($cache_file | path exists) {
        return
    }
    let $cache_expires_at =  ((ls $cache_file | get 0.modified) + ( $expiration | default $env._FORTNOX_CACHE_VALID_DURATION))
    if $cache_expires_at <= (date now) {
        (rm $cache_file)
        return
    }
    #log info $"Using cached result for key: '($key)', expires at: ($cache_expires_at)"
    (open $cache_file | from json)
}

# Saves value to file with cache key. Returns the given value.
export def save_to_file [cache_key: string, value: any] {
    let $cache_file = ($env._FORTNOX_CACHE_DIR | path join (_create_hash_file_name $cache_key ))
    ($value | to json -r | save -f $cache_file)
    return $value
}

export def function_call [cache_key: string, function: closure] {
    (load_from_file $cache_key | default (do $function { save_to_file $cache_key $in }))
}

