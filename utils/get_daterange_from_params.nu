export def main [
    params:
        record<
            year: int
            quarter: int
            month: int
            day: int 
        >
    date_affix: = "T00:00.0000+01:00"
] -> record<from: datetime, to: datetime> {

    if ($params | is-empty) { return {from: null, to: null }}

    let $year = (
        if ($params.year | is-empty) {
             date now | format date "%Y" 
        } else { 
            $params.year 
        } | into int
    )
     
    if not ($params.quarter | is-empty) {
        if not $params.quarter in 1..4 {
            error make {
                text: "Invalid date range"
                label: {
                    msg: "Invalid quarter, expected an integer: (1-4)"
                    span: (metadata $params.year).span
                }
            }
        }
        if not ($params.month | is-empty) {
            error make {
                text: "Invalid date range"
                label: {
                    msg: "'--month (-M)' is mutually exclusive with 'quarter'"
                    span: (metadata $params.year).span
                }
            }
        }
        if not ($params.day | is-empty) {
            error make {
                text: "Invalid date range"
                label: {
                    msg: "'--day (-D)' is mutually exclusive with 'quarter'"
                    span: (metadata $params.year).span
                }
            }
        }
        return {
            from: ($"($year)-(($params.quarter - 1) * 3 + 1)-01($date_affix)" | into datetime)
            to: (
                if $params.quarter == 4 {
                    (($"($year + 1)-01-01($date_affix)" | into datetime) - ("1ns" | into duration))
                } else {
                    (($"($year)-($params.quarter * 3 + 1)-01($date_affix)" | into datetime) - ("1ns" | into duration))
                }
            )
        }
    }



    let $month = (
        if ($params.month | is-empty) {
            (if ($params.year | is-empty) {
                date now | format date "%m" 
            } else { # default to january if "$params.year" is provided
                1
            })
        } else { 
            $params.month 
        } | into int
    )


    if not ($params.day | is-empty) {
        if not $params.day in 1..31 {
            error make {
                msg: "Invalid date range"
                label: {
                    text: "Invalid day, expect an integer: (1-31)"
                    span: (metadata $params.quarter).span
                }
            }
        }
        return {
            from: ($"($year)-($month)-($params.day)($date_affix)" | into datetime)
            to: (($"($year)-($month)-($params.day + 1)($date_affix)" | into datetime) - ("1ns" | into duration))
        }
    }

    if not ($params.month | is-empty) {
        if not $params.month in 1..12 {
            error make {
                msg: "Invalid date range"
                label: {
                    text: "Invalid month, expect an integer: (1-12)"
                    span: (metadata $params.quarter).span
                }
            }
        }

        return {
            from: ($"($year)-($month)-01($date_affix)")
            to: ($"($year)-($month + 1)-01($date_affix)" - ("1ns" | into duration) )
        }
    }


    if not ($params.year | is-empty) {
        if not $params.year in 1970.. {
            error make {
                text: "Invalid date range"
                label: {
                    msg: "Invalid year"
                    span: (metadata $params.year).span
                }
            }
        }
        let $from = ( $"($params.year)-01-01($date_affix)" | into datetime)

        #   format date $"($params.year)-%m-%dT%H:%M:%S.%9f"
        mut $to = ($from + ("360day" | into duration))
        while ($to | format date "%Y") == $params.year {
            $to = ($to + ("1day" | into duration))
        }
        $to = ($to - ("1ns" | into duration))
        
        return { 
            from: $from      
            to: $to 
        }
    }
    return { from: null, to: null}
}
