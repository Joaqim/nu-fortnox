
export def main [
        input: record,
        --remove-empty # Removes all empty values: 'null', "", [], {}. If 'false', removes only fields with value: 'null'
    ] -> record {
    ($input
        | items {|$key, value| [$key $value]}
        | reduce -f {} {|it, acc|
            if $it.1 == null or ($remove_empty and ($it.1 | is-empty)) {
                return $acc
            } 
            ($acc | upsert $it.0 $it.1)
        }
    )
}
