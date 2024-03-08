#{
    #for_year: $for_year
    #for_quarter: $for_quarter
    #for_month: $for_month
    #for_day: $for_day
    #date: $date
    #from: $from
    #from_date: $from_date
    #to_date: $to_date
#}

export def main [
    params: record<
        for_year: int
        for_quarter: int
        for_month: int
        for_day: int
        date: string
        from: string
        from_date: string
        to_date: string > = {}
    --for-year: int
    --for-quarter: int
    --for-month: int
    --for-day: int
    --date: string
    --from: string
    --from-date: string
    --to-date: string
    --date-affix = "T00:00.0000"
    --utc-offset = 1 # UTC+1 local Europe/Stockholm time
    --to-date-precision = 1ns
] -> record<from: datetime, to: datetime> {

    def _fallback_date [$date_format: string] any -> int {
        ($in
            | default (
                date now
                    | format date $date_format
            )
        )
    }

    if ([$for_year $for_quarter $for_month $for_day] | all {is-empty}) {
        if ([$from_date $from $date] | all { is-empty }) {
            return {
                from: null,
                to: null
            }
        }
        return {
            from: ($from_date  | default $from | default $date | into datetime | format date "%Y-%m-%d")
            to: ($to_date
                    | default ($date | _fallback_date '%Y-%m-%d')
                )
        }
    }

    let $year = ($for_year | default ($date | _fallback_date '%Y' | into int))

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
            from: ($"($year)-(($for_quarter - 1) * 3 + 1)-01($date_affix)" | into datetime --offset $utc_offset)
            to: (
                if $for_quarter == 4 {
                    (($"($year + 1)-01-01($date_affix)" | into datetime --offset $utc_offset) - ($to_date_precision | into duration))
                } else {
                    (($"($year)-($for_quarter * 3 + 1)-01($date_affix)" | into datetime --offset $utc_offset) - ($to_date_precision | into duration))
                }
            )
        }
    }

    let $month = ($for_month | _fallback_date '%m' | into int)


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
            from: ($"($year)-($month)-($for_day)($date_affix)" | into datetime --offset $utc_offset)
            to: (($"($year)-($month)-($for_day + 1)($date_affix)" | into datetime --offset $utc_offset) - ($to_date_precision | into duration))
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
            from: ($"($year)-($month)-01($date_affix)" | into datetime --offset $utc_offset)
            to: (($"($year)-($month + 1)-01($date_affix)" | into datetime --offset $utc_offset) - ($to_date_precision | into duration) )
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

        # Date range, whole year
        let $from = ( $"($for_year)-01-01($date_affix)" | into datetime --offset $utc_offset)
        let $to = (($"($for_year + 1)-01-01($date_affix)" | into datetime --offset $utc_offset) - ($to_date_precision | into duration))

        return {
            from: $from
            to: $to
        }
    }
    return { from: null, to: null}
}
