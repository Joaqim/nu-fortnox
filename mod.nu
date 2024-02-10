export-env {
    source ./init-env.nu
}

export module fortnox {
    
    export use ./fortnox/ *

    # Need this line to make sure function have access to $env
    use ./utils/ratelimit_sleep.nu
    use ./db_client/

    def --env main [] {
        if not (db_client validate_db_connection_string) {
            error make {
                msg: 'Invalid database connection string.',
                label: {
                    text: "Missing or invalid",
                    span: (metadata ($env.DB_CONNECTION_STRING)).span
                }
            }
        }

        if not (db_client has_collection 'credentials') {
            error make {
                msg: "Invalid Database"
                label: {
                    text: "Database is missing collection: 'credentials'",
                    span: (metadata $env.DB_CONNECTION_STRING).span
                }
            }
        }
        (invoices -l 10 -b --obfuscate -Q 1 --sort-order ascending )
        #(invoices -l 1 --filter-by-unbooked -b --obfuscate --no-cache -Q 1)
    }
}