
export def main [resources: string] -> list<record> {
    let documents = $in
    (match $resources {
        invoices => ( 
            $documents
            | reject --ignore-errors CustomerName CustomerEmail DeliveryAddress EmailInformation EDIInformation
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
        )
        customers => ( 
            $documents | get --ignore-errors CustomerNumber Country DeliveryCountry
        )
        _ => $documents
    })
}

