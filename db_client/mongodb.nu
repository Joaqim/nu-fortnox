
export def validate_db_connection_string [] -> bool {
    ($env.DB_CONNECTION_STRING =~ ^mongodb://)
}

export def has_collection [collection_name: string] -> bool {
    (mongosh $env.DB_CONNECTION_STRING --eval 'db.getCollectionNames().indexOf("credentials") != -1' --quiet | into bool)
}

export def update_one [collection_name: string, query: string, entry: string] {
    (mongosh $env.DB_CONNECTION_STRING --eval $"db.($collection_name).updateOne\(($query), { \$set: ($entry) })" --quiet | null)
}

export def find_one [
    collection_name: string,
    query: string,
    ] -> record {
    def parse_mongodb_document [
        document_string: string
        ] {
            def parse_mongodb_object [object_string: string] -> string {
                let match = (
                    $object_string 
                    | parse --regex "\\s*_?(.*):.*\('(.*)'\),?"
                ).0
                ($"($match.capture0): ($match.capture1),")
            }
            $document_string
                | lines --skip-empty
                | each { 
                    if $in =~ 'ObjectId|ISODate' {
                        return (parse_mongodb_object $in)
                    } else { $in }
                }
                | str join ""
                | from nuon
    }

    (parse_mongodb_document (
        mongosh $env.DB_CONNECTION_STRING --eval $"\"db.($collection_name).findOne\(($query)\)\"" --quiet)
    )
}