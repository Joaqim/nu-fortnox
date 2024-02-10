use std assert

use ../utils/get_daterange_from_params.nu

export def "Test" [] {
    assert equal (
            get_daterange_from_params --for-year 2001 --for-month 1 --for-day 1 --to-date-offset "1ns"
        ) (
            {
                from : ('2001-01-01' | into datetime) 
                to : (('2001-01-02' | into datetime) - ("1ns" | into duration))
            }
        )
}

export def "Test 2" [] {
    assert equal (
            get_daterange_from_params --for-year 2001 --for-month 1 --for-day 1 --to-date-offset "1day"
        ) (
            {
                from : ('2001-01-01' | into datetime) 
                to : ('2001-01-01' | into datetime)
            }
        )
}