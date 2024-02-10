
export def validate_db_connection_string [] -> bool {
    ($env.DB_CONNECTION_STRING =~ ^example://)
}

export def has_collection [collection_name: string] -> bool {
    error make { msg: "Not implemented "}
}

export def update_one [collection_name: string, query: string, entry: string] {
    error make { msg: "Not implemented "}
}

export def find_one [
    collection_name: string,
    query: string,
    ] -> record {
    error make { msg: "Not implemented "}
}
