use ../../utils/compact_record.nu

export def main [
    resources: string
    actions: record<put: any, post: any, get: any>
    --id: any
    --body: any
    ] record<method: any, action: any> -> {
    mut $result = { method: null, action: null }
    let $actions_values = ($actions | values | compact)

    if not ($actions_values | is-empty) {
        if (($actions_values | length) != 1) {
            error make {
                msg: "Unexpected multiple actions"
                label: {
                    text: "Expected only one --(put/post/get)--action"
                    span: (metadata $actions).span
                }
            }
        }

        if not ($resources == 'invoices') {
            error make {
                msg: $"Invalid resource for action"
                label: {
                    text: $"Resource '($resources)' does not have actions"
                    span: (metadata $actions).span
                }
            }
        }

        let $method = (match ($actions | compact_record ) {
            {put: $put_action} if $put_action =~ "^(update|bookkeep|cancel|credit|externalprint|warehouseready)$" => {"PUT"}
            {post: $post_action} if $post_action =~ "^(create)$" => {"POST"}
            {get: $get_action} if $get_action =~ "^(print|email|printreminder|preview|eprint|einvoice)$" => {"PUT"}
            _ => {
                error make {
                    msg: "Unexpected action"
                    # TODO: Dynamic label to link expected actions for method, i.e PUT => [update, bookkeep, ...] and vice versa
                    label: {
                        text: $"Invalid action: ($actions | compact_record | to nuon)"
                        span: (metadata $actions).span
                    }
                }
            }
        })

        mut action = $actions_values.0

        # These are just internal actions, we POST or PUT to {resource}/{id}/ without actually appending /update or /create
        if ($action =~ '^(update|create)') {
            if ($body | is-empty) {
                error make {
                    msg: $"Empty body for action ($action)"
                    label: {
                        text: $"Expected --body to be defined for ($method) request @ /($resources)/"
                        span: (metadata $actions).span
                    }
                }
            }
            if ($id | is-empty) {
                error make {
                    msg: $"Missing --id for ($action)"
                    label: {
                        text: $"Expected --id to be defined for ($method) request @ /($resources)/"
                        span: (metadata $actions).span
                    }
                }
            }
            $action = null
        } else if not ($body | is-empty) {
            error make {
                msg: "Unexpected body"
                label: {
                    text: $"Unexpected --body defined for ($method) request @ /($resources)/($action)"
                    span: (metadata $body).span
                }
            }
        }

        $result.action = $action
        $result.method = $method
    }
    return $result
}