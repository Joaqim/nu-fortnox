
use std log
export def main [
    $resources: string
    $input: any
    --id: int
    --action: string
    --body: any
    ] -> record<id: int, ids: list<int>, body: any> {
    if ($input | is-empty) {
        return {id: $id, ids: [], body: $body}
    }

    mut $result = {id: $id, ids: [], body: null}

    match $resources {
        'invoices' => {
            if (($input | describe) =~ 'list<int>|int|list<string>') {
                if not ($id | is-empty) {
                    error make {
                        msg: "Unexpected param"
                        label: {
                            text: "Cannot use --invoice-number while using pipeline input for ids: list<int>"
                            span: (metadata $id).span
                        }
                    }
                }
                if (($input | length) == 1) {
                    $result.id = $input.0
                } else {
                    $result.ids = ($input | into int)
                }
            } else if ($action =~ '(update|create)' ) {
                # Assume pipeline is used as body input instead of '--body'
                if not ($body | is-empty) {
                    error make {
                        msg: "Unexpected param"
                        label: {
                            text: "Cannot use '--body' while using pipeline input."
                            span: (metadata $body).span
                        }
                    }
                }
                if  ($input | get -i Invoice | is-empty) {
                    error make {
                        msg: 'Invalid body'
                        label: {
                            text: "Expected body to contain: { Invoice: {...} }"
                            label: (metadata $input).span
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