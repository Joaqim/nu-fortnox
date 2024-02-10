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

# https://github.com/amtoine/nu-git-manager/blob/main/toolkit.nu

export def "fortnox version" []: nothing -> record<version: string, branch: string, commit: string, date: datetime> {
    let $current_dir = ($env.CURRENT_FILE | path dirname)
    #let mod = $env.NUPM_HOME | path join "modules" "nu-fortnox" "mod.nu"
    #if ($current_dir != 'nu-') {
    let $nu_fortnox_path = $current_dir | path join 'nu-fortnox'
    let $nupm_nuon = $nu_fortnox_path | path join 'nupm.nuon'
    if not ( $nupm_nuon | path exists) {
        error make {
            msg: "Failed to get 'nu-fortnox' version."
            label: {
                text: "Path does not contain a 'nupm.nuon' file or doesn't exist."
                span: (metadata $nu_fortnox_path).span
            }
        }
    }

    let v = (open $nupm_nuon).version
    let n =  ^git -C $nu_fortnox_path describe | parse "{v}-{n}-{r}" | into record | get n? | default 0

    return {
        version: $"($v)+($n)"
        branch: $"(^git -C $nu_fortnox_path branch --show-current)"
        commit: $"(^git -C $nu_fortnox_path rev-parse HEAD)"
        date: (date now | to nuon)
    }
}