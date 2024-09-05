# see the version of nu-fortnox that is currently installed
#
# # Examples
# ```nushell
# # get the version of nu-fortnox
# fortnox version
# ```
export def "fortnox version" []: nothing -> record<version: string, branch: string, commit: record<message: string, hash: string, date: datetime>> {
    mut $install_dir = ($env.CURRENT_FILE? | path dirname | path join "nu-fortnox")

    if not ($env.NUPM_HOME? | is-empty) {
        let $modules_dir = $env.NUPM_HOME | path join "modules"
        $install_dir = ($modules_dir | path join "nu-fortnox")
    }

    if not ($install_dir | path exists) {
        error make {
            msg: "Failed to find installation path of nu-fortnox."
        }
    }

    let $nupm_pkg_file = (open ($install_dir | path join "nupm.nuon"))
    let $package_name = $nupm_pkg_file.name

    let $v = $nupm_pkg_file.version
    let $n =  ^git -C $install_dir describe --tags --abbrev=0 | parse "{v}-{n}-{r}" | into record | get n? | default 0

    let $last_commit_msg = ^git -C $install_dir log --pretty=format:%s -n 1 | lines --skip-empty | str join ";"
    let $last_commit_date = ^git -C $install_dir log --pretty=format:%aD -n 1 | into datetime
    {
        version: $"($v)+($n)"
        branch: (^git -C $install_dir branch --show-current)
        commit: {
            message: ($last_commit_msg)
            hash: (^git -C $install_dir rev-parse HEAD)
            date: ($last_commit_date)
        }
    }
}
