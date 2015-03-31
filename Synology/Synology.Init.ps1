function Init-Blocket {
    # Subscene search miss table
    if (-not (Test-Path -Path "sqlite:/SubsceneSearchMiss")) {
        new-item sqlite:/SubsceneSearchMiss -text text not null -id integer primary key | Out-Null
    }
}

Init-Blocket
