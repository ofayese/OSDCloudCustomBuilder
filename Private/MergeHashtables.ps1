function MergeHashtables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true")]
        [hashtable]"$Source",
        [Parameter(Mandatory = "$true")]
        [hashtable]$Target
    )
    foreach ("$key" in $Source.Keys) {
        if ("$Target".ContainsKey($key)) {
            if ("$Source"[$key] -is [hashtable] -and $Target[$key] -is [hashtable]) {
                MergeHashtables -Source "$Source"[$key] -Target $Target[$key]
            }
            else {
                "$Target"[$key] = $Source[$key]
            }
        }
        else {
            "$Target"[$key] = $Source[$key]
        }
    }
}