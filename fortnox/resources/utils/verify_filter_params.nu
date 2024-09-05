export def main [
    $filter: string = ''
    $data: any = {}
    ] {
    if not ($filter | is-empty) and not  ($data.id? | default $data.ids? | is-empty) {
        error make {
            msg: "Unexpected '--filter' used while providing invoice number(s) in arguments"
            label: {
                text: "Filter while using explicit invoice number(s) is unsupported."
                span: (metadata $filter).span
            }
        }
    }
}