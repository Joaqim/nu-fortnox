let $paths = (open Fortnox-swagger.yaml | get paths)
const $fortnox_resources = 'invoices'

#let $get_params = ($paths | get $"/3/($fortnox_resources).get.parameters")
let $get_params = ($paths | get $"/3/($fortnox_resources)" | get get.parameters)
let $post_params = ($paths | get $"/3/($fortnox_resources)" | get post.parameters)

let $by_id = ($paths | get $"/3/($fortnox_resources)/{DocumentNumber}" --ignore-errors | default {} )

let $get_by_id_params = ($by_id | get get.parameters? --ignore-errors)
let $put_by_id_params = ($by_id | get put.parameters? --ignore-errors)
let $post_by_id_params = ($by_id | get post.parameters? --ignore-errors)

def params_to_nu_args [
    $params: list<record<name: string, in: string, description: string, required: bool, type: string, enum: list<string>, schema: any>>
    ] -> string {
    ($params | each {
        $"--($in.name)"
    } | str join '-- ')
}

export def main [] {
    print $get_params
    print ($get_params | first | describe)
    print $post_params
    print $by_id
    print $get_by_id_params
    print $put_by_id_params
    print $post_by_id_params
}