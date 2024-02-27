export def main [params: record] -> record {
    def _into_datetime [] any -> datetime {
        (if ($in | describe) == 'date' { $in } else { ($in | into datetime) })
    }

    ($params
        | items {|$key, $value| [$key, $value] }
        | reduce -f {} {|it, acc|
            if $it.1 == null or ($it.1 | is-empty) {
                return ($acc)
            }

            if $it.0 =~ "^(lastmodified|invoicedate|fromdate|todate)$" {
                mut $date_format = "%Y-%m-%d"

                # Last modified date string allows for more precision with addition of Hours and Minutes
                if ($it.0 == 'lastmodified') {
                    ($date_format | append ' %H:%M')
                }

                return ($acc
                    | upsert $it.0 ($it.1 
                        | _into_datetime 
                        | format date $date_format 
                        | url encode
                    )
                )
            }

            ($acc | upsert $it.0 ($it.1 | into string | url encode))
         }
    )
}