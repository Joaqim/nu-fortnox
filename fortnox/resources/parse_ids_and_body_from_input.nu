
export def main [
    $resources: string
    $input: any
    --id: int
    --body: any
    ] -> record<id: int, ids: list<int>, body: any> {
    if ($input | is-empty) {
        return {id: $id, ids: [], body: $body}
    }

    mut $result = {id: $id, ids: [], body: null}

    match $resources {
        'invoices' => {
            if (($input | describe) =~ 'list<int>|int') {
                if not ($id | is-empty) {
                    error make {
                        msg: "Unexpected param"
                        label: {
                            text: "Cannot use --invoice-number while using pipeline input for ids: list<int>"
                            span: (metadata $id).span
                        }
                    }
                }
                $result.ids = $input
            } else {
                # Assume input is used as input for --body
                if not ($body | is-empty) {
                    error make {
                        msg: "Unexpected param"
                        label: {
                            text: "Cannot use '--body' while using pipeline input."
                            span: (metadata $body).span
                        }
                    }
                }
                $result.body = $input
            }
        }
        _ => {
            error make {
                msg: 'Unsupported resource'
                label: {
                    text: $"Invalid resource for using pipeline input: ($resources)"
                    span: (metadata $resources).span
                }
            }
        }     
    }

    ($result)
}