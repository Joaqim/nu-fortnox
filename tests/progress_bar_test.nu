use ../utils/progress_bar.nu

use std assert
use std log

export def 'Test progress bar wrapper' [] {
    assert equal (
        progress_bar [1 2 3 4] {|$current_value|
            { id: $current_value }
        }
    ) ([{id: 1}, {id: 2}, {id: 3}, {id: 4}])

    # One limitation is that the accumulator and return result of progress_bar will always be a list
    assert equal (
        progress_bar [1 2 3 4] {|$current_value $acc|
            ([0 ...$acc] | last) + $current_value
        }
    ) ([ 1 3 6 10 ])
}