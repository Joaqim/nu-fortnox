
export def update_credentials [
        --access-token: string,
        --refresh-token: string,
        --expires-in: int
    ] -> string {
    let $expires_at = ((date now) + ($expires_in | into duration --unit sec) | to nuon)
    let $entry = ([
            "{"
            $"expiresAt: ISODate\("($expires_at)"\),"
            $'accessToken: "($access_token)",'
            $'refreshToken: "($refresh_token)"'
            "}"
        ] | str join "")

    (update_one 'credentials' $env._FORTNOX_DB_CREDENTIALS_QUERY $entry)
    ($access_token)
}

export def fetch_credentials [
    ] -> record<clientIdentity: string, clientSecret: string, accessToken: string, expiresAt: string> {
    (find_one 'credentials' $env._FORTNOX_DB_CREDENTIALS_QUERY)
}

export def validate_db_connection_string [] -> bool {
    ($env.DB_CONNECTION_STRING =~ ^mongodb://)
}

def _mongosh [eval: string --current-retry-count=0] {
    try {
        return (mongosh $env.DB_CONNECTION_STRING --eval $eval --quiet)
    } catch {|err|
        # Prevents infinite loop, exits after reaching max retries:
        if $current_retry_count > 5 {
            error make {
                msg: $"Request failed after ($current_retry_count) tries - ($err | to nuon)",
                label: {
                    text: $"mongosh failed with eval: '$eval'",
                    span: (metadata $eval).span
                }
            }
        }
        return (_mongosh $eval --current-retry-count=($current_retry_count + 1))
    }
}

export def has_collection [collection_name: string] -> bool {
    (_mongosh 'db.getCollectionNames().indexOf("credentials") != -1'| into bool)
}

export def update_one [collection_name: string, query: string, entry: string] {
    (_mongosh $"db.($collection_name).updateOne\(($query), { \$set: ($entry) })"| null)
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
        _mongosh $"\"db.($collection_name).findOne\(($query)\)\"")
    )
}