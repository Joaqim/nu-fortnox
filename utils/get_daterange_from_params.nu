export def main [
    --for-year: int 
    --for-quarter: int
    --for-month: int
    --for-day: int 
    --date-affix = "T00:00.0000+01:00"
    --to-date-offset = "0ns"
] -> record<from: datetime, to: datetime> {
    if ([$for_year $for_quarter $for_month $for_day] | all {is-empty}) {
        return {from: null, to: null}
    }

    let $year = (
        if ($for_year | is-empty) {
             date now | format date "%Y" 
        } else { 
            $for_year 
        } | into int
    )
     
    if not ($for_quarter | is-empty) {
        if not ($for_quarter in 1..4) {
            error make {
                text: "Invalid date range"
                label: {
                    msg: "Invalid quarter, expected an integer: (1-4)"
                    span: (metadata $for_quarter).span
                }
            }
        }
        if not ($for_month | is-empty) {
            error make {
                text: "Invalid date range"
                label: {
                    msg: "'--month (-M)' is mutually exclusive with 'quarter'"
                    span: (metadata $for_month).span
                }
            }
        }
        if not ($for_day | is-empty) {
            error make {
                text: "Invalid date range"
                label: {
                    msg: "'--day (-D)' is mutually exclusive with 'quarter'"
                    span: (metadata $for_day).span
                }
            }
        }
        return {
            from: ($"($year)-(($for_quarter - 1) * 3 + 1)-01($date_affix)" | into datetime)
            to: (
                if $for_quarter == 4 {
                    (($"($year + 1)-01-01($date_affix)" | into datetime) - ($to_date_offset | into duration))
                } else {
                    (($"($year)-($for_quarter * 3 + 1)-01($date_affix)" | into datetime) - ($to_date_offset | into duration))
                }
            )
        }
    }



    let $month = (
        if ($for_month | is-empty) {
            (if ($for_year | is-empty) {
                date now | format date "%m" 
            } else { # default to january if "$params.year" is provided
                1
            })
        } else { 
            $for_month 
        } | into int
    )


    if not ($for_day | is-empty) {
        if not ($for_day in 1..31) {
            error make {
                msg: "Invalid date range"
                label: {
                    text: "Invalid day, expect an integer: (1-31)"
                    span: (metadata $for_day).span
                }
            }
        }
        return {
            from: ($"($year)-($month)-($for_day)($date_affix)" | into datetime)
            to: (($"($year)-($month)-($for_day + 1)($date_affix)" | into datetime) - ($to_date_offset | into duration))
        }
    }

    if not ($for_month | is-empty) {
        if not ($for_month in 1..12) {
            error make {
                msg: "Invalid date range"
                label: {
                    text: "Invalid month, expect an integer: (1-12)"
                    span: (metadata $for_month).span
                }
            }
        }

        return {
            from: ($"($year)-($month)-01($date_affix)")
            to: ($"($year)-($month + 1)-01($date_affix)" - ($to_date_offset | into duration) )
        }
    }


    if not ($for_year | is-empty) {
        if not ($for_year in 1970..) {
            error make {
                text: "Invalid date range"
                label: {
                    msg: "Invalid year"
                    span: (metadata $for_year).span
                }
            }
        }
        let $from = ( $"($for_year)-01-01($date_affix)" | into datetime)

        #   format date $"($params.year)-%m-%dT%H:%M:%S.%9f"
        mut $to = ($from + ("360day" | into duration))
        while ($to | format date "%Y") == $for_year {
            $to = ($to + ("1day" | into duration))
        }
        $to = ($to - ($to_date_offset | into duration))
        
        return { 
            from: $from      
            to: $to 
        }
    }
    return { from: null, to: null}
}
