export def main [
        flags: record,
        --filter-by-affix (-a) = "filter-by",
        --filter-override (-F): string
    ] -> string {

    let filter = (
        ($flags
            | upsert ($filter_override | default _) ($filter_override != null)
            | items {|$key, value| [$key $value]}
            | each { if ($in.1) { return $in.0 } }
            | flatten
        )
    )

    if ($filter | length) > 1 {
        error make {
            msg: $"Unexpected filter\(s\): '($filter | str join ', ')'",
            label: {
                text: $"Expected only one of '--($filter_by_affix)-($flags | items {|$key| $key } | str join /)' for invoice status."
                span: (metadata $flags).span
            }
        }
    } else if ($filter | length ) == 0 {
        return null
    }

    ($filter | get 0)
}

