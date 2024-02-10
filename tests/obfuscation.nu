use ../fortnox/resources/obfuscate_fortnox_resource.nu

export def "Can obfuscate Customer information in invoice" [] {
    const $mockInvoice = {
        "CustomerName": "Confidential",
        "CustomerEmail": "confidential@mail.com",
        "EmailInformation": {
            "EmailTo": "confidential@mail.com"},
        "Country": Sverige,
        "City": Gothenburg,
        "DeliveryCity": Gothenburg,
        "DeliveryCountry": Sverige 
    }

    assert equal (
            obfuscate_fortnox_resource invoices $mockInvoice
    ) (
            $mockInvoice | reject CustomerName CustomerEmail EmailInformation City DeliveryCity
    )
}

