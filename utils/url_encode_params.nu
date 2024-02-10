export def main [params: record] -> record {
    ($params
        | items {|$key, $value| [$key, $value] }
        | reduce -f {} {|it, acc|
                if $it.1 == null or ($it.1 | is-empty) {
                    return ($acc)
                }
                # Alt:
                #if ($it.1 | describe) == date {
                if $it.0 =~ "^(lastmodified|invoicedate|fromdate|todate)$" {
                    return ($acc | upsert $it.0 ($it.1 | format date "%Y-%m-%d" | url encode))
                }
                ($acc | upsert $it.0 ($it.1 | into string | url encode))
         }
    )
}