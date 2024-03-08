use std log
# Indices must be be either list<int>, range or integer ( for single index ), throws error otherwise
export def main [$indices: any, func: closure --start-offset = 0] -> list<any> {
    if (($indices | describe) == 'int') {
        return [(do $func $indices )]
    }

    let $indices_count: int = (
        match ($indices | describe) {
            'list<int>' => { ($indices | length) }
            'list<any>' => { ($indices | length) }
            'range' => { (($indices | math max) - ($indices | math min)) + 1}
            _ => {
                error make {
                    msg: "Unexpected 'indices' format for progress_bar"
                    label: {
                        text: $"Expected 'list<int>',int or range, got: ($indices | describe)"
                    }
                }
            }
        }
    )

    ansi cursor_off
    let $result = ($indices | enumerate | skip $start_offset | reduce --fold [] {|$current,  $acc|
        let $index = $current.index + 1
        let $item_index = $current.item
        let $percentage = (($index / $indices_count) * 100 | into string --decimals 0 )
        print -n $"(ansi -e '1000D')($percentage | into string --decimals 0 )% \(($index)/($indices_count)\)(ansi erase_line_from_cursor_to_end)"
        ($acc | append (do $func $item_index $acc))
    })

    print -n ($"(ansi -e '1000D')(ansi erase_entire_line)")
    ansi cursor_on
    return $result
}

