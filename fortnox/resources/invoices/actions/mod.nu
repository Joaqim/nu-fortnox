use ../../utils/parse_ids_and_body_from_input.nu
use ../../utils/fortnox_resource_url.nu
use ../../utils/parse_actions_from_params.nu
use ../../../../utils/progress_bar.nu

use ../../fortnox_request.nu

use std log

def _fortnox_invoices_action_put__completion [] -> list<string> {
    (['update', 'bookkeep', 'cancel', 'credit', 'externalprint', 'warehouseready'])
}

def _fortnox_invoices_action_post__completion [] -> list<string> {
    (['create'])
}

def _fortnox_invoices_action_get__completion [] -> list<string> {
    (['print', 'email', 'printreminder', 'preview', 'eprint', 'einvoice', 'invoice'])
}

const $RESOURCES = 'invoices'
const $FORTNOX_PAYLOAD_KEYS = {singular: 'Invoice', plural: 'Invoices'}

def request_by_id [$METHOD $action $data --dry-run --no-cache]: {
    let $fortnox_action = (parse_actions_from_params $RESOURCES $METHOD $action --id $data.id --ids $data.ids)
    let $url: string = (fortnox_resource_url $RESOURCES --action $fortnox_action  --id $data.id)
    if ($dry_run) {
        log info ($"Dry-run: '($METHOD)' @ ($url)")
        return { '@url': $url }
    }
    (fortnox_request $METHOD $url --no-cache=($no_cache) | get $FORTNOX_PAYLOAD_KEYS.singular --ignore-errors)
}

def process_ids [$METHOD $action $data --dry-run --no-cache ]: {
    if not ($data.ids | is-empty) {
        return {  $FORTNOX_PAYLOAD_KEYS.plural: (
                progress_bar $data.ids {|$current_id|
                    (request_by_id $METHOD $action {id: $current_id ids: []} --dry-run=($dry_run) --no-cache=($no_cache))
                }
            )
        }
    }
    return { $FORTNOX_PAYLOAD_KEYS.singular: ( request_by_id $METHOD $action $data --dry-run=($dry_run) --no-cache=($no_cache)) }
}


export def 'invoices get' [
    $action: string@_fortnox_invoices_action_get__completion = "invoice" # Default action fetches invoice(s)
    $invoice_number: any = null # Allow pipeline input of list of invoice numbers
    --dry-run
    --no-cache
    ] {
    let $data = (parse_ids_and_body_from_input $RESOURCES $in --id $invoice_number --action $action)
    const $METHOD = 'get'
    (process_ids $METHOD $action $data --dry-run=($dry_run) --no-cache=($no_cache))
}

export def 'invoices put' [
    $action: string@_fortnox_invoices_action_put__completion
    $invoice_number: any = null # Allow pipeline input of list of invoice numbers
    $body: any = {}
    --dry-run
    ] {
    let $data = (parse_ids_and_body_from_input $RESOURCES $in --id $invoice_number --action $action --body $body)
    const $METHOD = 'put'
    return (process_ids $METHOD $action $data --dry-run=($dry_run) --no-cache=(true))
}

export def 'invoices post' [
    $action: string@_fortnox_invoices_action_post__completion
    $body: any = {}
    --dry-run
    ] {
    let $data = (parse_ids_and_body_from_input $RESOURCES $in --action $action --body $body)
    const $METHOD = 'post'
    return (process_ids $METHOD $action $data --dry-run=($dry_run) --no-cache=(true))
}