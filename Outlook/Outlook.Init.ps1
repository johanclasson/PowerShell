function Init-SQLite {
    # Credential table
    if (-not (Test-Path -Path "sqlite:/ForwardedOutlookMail")) {
        new-item sqlite:/ForwardedOutlookMail -EntryID string primary key | Out-Null
    }
}

Init-SQLite
