
export def main [resources: string, resource: record] -> record {
    (match $resources {
        invoices => ( 
            $resource
            | reject --ignore-errors CustomerName CustomerEmail DeliveryAddress EmailInformation
            | items {|$key, value| [$key $value]}
            | reduce -f {} {|it, acc|
                (if ( $it.0 =~ "^(City|ZipCode|Phone1|Phone2)$" ) or ( $it.0 =~ "^Delivery(?!Country)") {
                    $acc
                } else {
                    ($acc | upsert $it.0 $it.1)
                }
                )
            }
        )
        customers => ( 
            $resource | get --ignore-errors CustomerNumber Country DeliveryCountry
        )
        _ => $resource
    })
}

