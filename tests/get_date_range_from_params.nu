use std assert

use ../utils/get_daterange_from_params.nu

export def "Create date range params 'from' and 'to' with precision of '1 nano second'" [] {
    assert equal (
            get_daterange_from_params --for-year 2001 --to-date-precision 1ns
        ) (
            {
                from : ('2001-01-01' | into datetime) 
                to : (('2002-01-01' | into datetime) - (1ns | into duration))
            }
        )
}

export def "Create date range params 'from' and 'to' with precision of '1 day'" [] {
    assert equal (
            get_daterange_from_params --for-year 2001 --to-date-precision 1day
        ) (
            {
                from : ('2001-01-01' | into datetime) 
                to : ('2001-12-31' | into datetime)
            }
        )
}