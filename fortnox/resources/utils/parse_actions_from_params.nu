use ../../../utils/compact_record.nu
use ./fortnox_payload_keys.nu


#  NOTE: actions with values: 'none', 'update' & 'create' are only used internally,
# we POST, PUT or GET @ api/{resource}/{id}/<action> without actually appending them
# to our url for Fortnox requests, 'update' and 'create' expects a 'body' input,
# either as --body or from input.
export def main [
    resources: string
    method: string
    action: string
    --id: int
    --ids: list<int>
    --body: any
    ] -> string {

    match $resources {
        'invoices' => {}
        _ => {
            error make {
                msg: $"Invalid resource for action"
                label: {
                    text: $"Resource '($resources)' does not have any actions"
                    span: (metadata $action).span
                }
            }
        }
    }

    let $method = (match ($method | str downcase) {
        'put' if $action =~ "^(update|bookkeep|cancel|credit|externalprint|warehouseready)$" => {'PUT'}
        'post' if $action =~ "^(create)$" => {'POST'}
        'get' if $action =~ "^(print|email|printreminder|preview|eprint|einvoice|invoice)$" => {'GET'}
        _ => {
            error make {
                msg: $"Unexpected action while using method: ($method)"
                label: {
                    text: $"Missing or invalid action: ($action)"
                    span: (metadata $action).span
                }
            }
        }
    })

    if ($action =~ '^(none|invoice|)$') {
        return ''
    }

    let $payload_keys = (fortnox_payload_keys $resources)

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
        if ($body | get $payload_keys.singular --ignore-errors | is-empty) {
            error make {
                msg: $"Invalid payload for action ($action)"
                label: {
                    text: $"Expected --body to have payload: '{ ($payload_keys.singular): {...} }'  - ($method) request @ /($resources)/"
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