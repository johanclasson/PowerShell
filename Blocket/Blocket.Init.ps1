function Init-Blocket {
    # BlocketSearchHits table
    if (-not (Test-Path -Path "sqlite:/BlocketSearchHits")) {
        new-item sqlite:/BlocketSearchHits -uri text not null -id integer primary key | Out-Null
    }
    if (-not (Test-Path -Path "sqlite:/BlocketSearchQuery")) {
        new-item sqlite:/BlocketSearchQuery -text text not null -id integer primary key | Out-Null
    }
    # TODO: Link query and hits tables so that several queries (with target emails) can trigger the same hits.
    # Err... Is this really what I want?
}

Init-Blocket
