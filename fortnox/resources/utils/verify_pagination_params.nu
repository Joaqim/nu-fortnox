
export def main [pages: range params: record] -> {
    if $pages != 1..1 and $params.limit != 100 {
        error make {
            msg: "Unexpected param value"
            label: {
                text: "Expected '--limit (-l)' left at default 100 when fetching more than page '--page (-p)'."
                span: (metadata $params.limit).span
            }
        }
    }

    if $pages == 1..1 and $params.limit > 100 {
        error make {
            msg: "Unexpected param value"
            label: {
                text: "If you want to fetch more than 100 resources, use a higher page range '--page (-p)', default: one page = 1..1"
                span: (metadata $params.limit).span
            }
        }
    }

    const $non_filtering_params = [limit sortorder sortby]
    if (30 in $pages) and ( $params | reject  $non_filtering_params | compact_record --remove-empty | is-empty ) {
        error make {
            msg: "Unexpected param value"
            label: {
                text: "When fetching a large amount of pages (--page = 1..) make sure to use filtering to reduce amount of calls to Fortnox API."
                span: (metadata $pages).span
            }
        }
    }
}