
export-env { 
    source ./init-env.nu 
}

export use ./fortnox/

export def main [--help (-h)] {
    print "Usage (fortnox invoices -h):\n"
    (fortnox invoices -h)
}

# https://github.com/amtoine/nu-git-manager/blob/main/toolkit.nu

export def "fortnox version" []: nothing -> record<version: string, branch: string, commit: string, date: datetime> {
    let $current_dir = ($env.CURRENT_FILE | path dirname)
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
    let n =  ^git -C $nu_fortnox_path describe --tags --abbrev=0 | parse "{v}-{n}-{r}" | into record | get n? | default 0
    let last_commit_date = ^git log --pretty=format:%aD -n 1 | into datetime

    return {
        version: $"($v)+($n)"
        branch: $"(^git -C $nu_fortnox_path branch --show-current)"
        commit: $"(^git -C $nu_fortnox_path rev-parse HEAD)"
        last_commit: $last_commit_date
    }
}
