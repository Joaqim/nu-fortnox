use std assert
use ../../fortnox/resources/create_fortnox_resource_url.nu

export def "Create resource url for Fortnox API" [] {
    assert equal (
        create_fortnox_resource_url invoices
        | url parse | select path
    ) ({ path: '/3/invoices/'})
}

export def "Create GET resource url with params for Fortnox API" [] {
    assert equal (
        create_fortnox_resource_url invoices --page 1 {
            limit: 100
            sortby: invoicedate
            sortorder: descending
            fromdate: 2024-01-01 # NOTE: This is actually a datetime object, will be converted to string %Y-%m-%d
        } | url parse | select path params
    ) ({ 
        path: '/3/invoices/'
        params: {
            limit: "100" # url encode explicitly uses strings
            sortby: "invoicedate"
            sortorder: "descending"
            fromdate: "2024-01-01"
            page: "1"
        }
    })
}

export def "Create POST resource url for invoices in Fortnox API" [] {
    assert equal (
        create_fortnox_resource_url invoices --additional-path bookkeep {
        } | url parse | select path params
    ) ({ 
        path: '/3/invoices/bookkeep/'
        params: { }
    })
}

export def "Create POST and GET resource urls for vouchers in series S from Fortnox API" [] {
    assert equal (
        create_fortnox_resource_url vouchers --additional-path S {
        } | url parse | select path params
    ) ({ 
        path: '/3/vouchers/S/'
        params: { }
    })

    assert equal (
        create_fortnox_resource_url vouchers --id 1001 --additional-path S {
        } | url parse | select path params
    ) ({ 
        path: '/3/vouchers/S/1001'
        params: { }
    })
}