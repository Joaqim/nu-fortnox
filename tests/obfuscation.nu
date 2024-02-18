use ../fortnox/resources/obfuscate_fortnox_resource.nu

export def "Can obfuscate Customer information in invoices" [] {
    const $mockInvoices = {Invoices: [[CustomerName, CustomerEmail, EmailInformation, Country, City, DeliveryCity, DeliveryCountry]; [Confidential, confidential@mail.com, {EmailTo: confidential@mail.com}, Sverige, Gothenburg, Gothenburg, Sverige]]}

    assert equal (
            $mockInvoices | obfuscate_fortnox_resource 
    ) (
            $mockInvoices.Invoices | reject CustomerName CustomerEmail EmailInformation City DeliveryCity
    )
}

