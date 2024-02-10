def _create_hash_file_name [key: string] {
    ($key | hash md5 | str substring 0..31)
}

export def load_from_file [key: string] -> {
    let $cache_file = ($env._FORTNOX_CACHE_DIR | path join (_create_hash_file_name $key ))
    if not ($cache_file | path exists) {
        return
    }
    let $cache_expires_at =  ((ls $cache_file | get 0.modified) + $env._FORTNOX_CACHE_VALID_DURATION)
    if $cache_expires_at <= (date now) {
        (rm $cache_file)
        return
    }

    (open $cache_file | from json)
}

export def save_to_file [key: string, value: any] {
    let $cache_file = ($env._FORTNOX_CACHE_DIR | path join (_create_hash_file_name $key ))
    ($value | to json -r | save -f $cache_file)
}