
export def main [] -> table {
    let fortnox_payload = $in
    ($fortnox_payload 
        | items {|$resource_key $documents|
            (match $resource_key {
                Invoices => ( 
                    $documents
                    | each {
                        reject --ignore-errors CustomerName CustomerEmail DeliveryAddress EmailInformation EDIInformation
                        | items {|$key, value| [$key $value]}
                        | reduce -f {} {|it, acc|
                            (
                                if ( $it.0 =~ "^(City|Address1|ZipCode|Phone1|Phone2)$" ) 
                                or ( $it.0 =~ "^Delivery(?!Country)") 
                                {
                                    $acc
                                } else {

                                    ($acc | upsert $it.0 $it.1)
                                }
                            )
                        }
                    }
                )
                Customers => ( 
                    $documents | get --ignore-errors CustomerNumber Country DeliveryCountry
                )
                MetaInformation => $documents
                _ => $documents
            })
        } | flatten
    )
}

