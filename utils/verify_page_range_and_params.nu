
export def main [page: range params: record] -> {
    if $page != 1..1 and $params.limit != 100 {
        error make {
            msg: "Unexpected param value"
            label: {
                text: "Expected '--limit (-l)' left at default 100 when fetching more than page '--page (-p)'."
                span: (metadata $params.limit).span
            }
        }
    }
    if $page == 1..1 and $params.limit > 100 {
        error make {
            msg: "Unexpected param value"
            label: {
                text: "If you want to fetch more than 100 resources, use a higher page range '--page (-p)', default: one page = 1..1"
                span: (metadata $params.limit).span
            }
        }
    }
    if (10 in $page) and ( $params | reject limit sortorder sortby | compact_record --remove-empty | is-empty ) {
        error make {
            msg: "Unexpected param value"
            label: {
                text: "When fetching a large amount of pages (--page = 1..) make sure to use filtering to reduce amount of calls to Fortnox API."
                span: (metadata $page).span
            }
        }
    }
}