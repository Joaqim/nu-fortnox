use ../../utils/compact_record.nu

export def main [
    resources: string
    method: string
    action: string 
    --id: int
    --ids: list<int>
    --body: any
    ] -> string {
    if not ($resources == 'invoices') {
        error make {
            msg: $"Invalid resource for action"
            label: {
                text: $"Resource '($resources)' does not have actions"
                span: (metadata $action).span
            }
        }
    }

    let $method = (match ($method | str downcase) {
        'put' if $action =~ "^(update|bookkeep|cancel|credit|externalprint|warehouseready)$" => {"PUT"}
        'post' if $action =~ "^(create)$" => {"POST"}
        'get' if $action =~ "^(print|email|printreminder|preview|eprint|einvoice)$" => {"GET"}
        _ => {
            error make {
                msg: $"Unexpected action for method: ($method)"
                label: {
                    text: $"Missing or invalid action: ($action)"
                    span: (metadata $action).span
                }
            }
        }
    })

    # These are just internal actions, we POST or PUT to {resource}/{id}/ without actually appending /update or /create to our Fortnox API url
    if ($action =~ '^(update|create)') {
        if ($body | is-empty) {
            error make {
                msg: $"Empty body for action ($action)"
                label: {
                    text: $"Expected --body to be defined for ($method) request @ /($resources)/"
                    span: (metadata $body).span
                }
            }
        }
        if ($body.Invoice? | is-empty) {
            error make {
                msg: $"Invalid Invoice payload for action ($action)"
                label: {
                    text: $"Expected --body to have payload: '{ Invoice: {...} }'  - ($method) request @ /($resources)/"
                    span: (metadata $body).span
                }
            }
        }
        if ($id | is-empty) {
            error make {
                msg: $"Missing --id for ($action)"
                label: {
                    text: $"Expected --id to be defined for ($method) request @ /($resources)/"
                    span: (metadata $id).span
                }
            }
        }
        if not ($ids | is-empty) {
            error make {
                msg: $"Unexpected multiple ids provided for ($action)"
                label: {
                    text: $"Cannot use multiple ids pipeline input for ($method) request @ /($resources)/"
                    span: (metadata $id).span
                }
            }
        }
        return ""
    } else if not ($body | is-empty) {
        error make {
            msg: "Unexpected body"
            label: {
                text: $"Unexpected --body defined for ($method) request @ /($resources)/($action)"
                span: (metadata $body).span
            }
        }
    }
    return $action
}