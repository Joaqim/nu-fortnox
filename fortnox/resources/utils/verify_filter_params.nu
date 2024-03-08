export def main [$filter: string = '', $data: any = {}] {
    if not ($filter | is-empty) and not  ($data.id? | default $data.ids? | is-empty) {
        error make {
            msg: $"Unexpected '--filter' used while providing an invoice number in arguments"
            label: {
                text: $"Filtering by invoice number and pagination at the same time isn't supported"
                span: (metadata $filter).span
            }
        }
    }
}