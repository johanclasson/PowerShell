function Init-SQLite {
    # Database
    if (-not (Test-Path -Path "c:\DB")) {
        New-Item c:\DB -ItemType Dir -Force | Out-Null
    }
    new-psdrive -name sqlite -psp SQLite -root "Data Source=c:\DB\powershell.db;Version=3;" -Scope Global | Out-Null
    # Credential table
    if (-not (Test-Path -Path "sqlite:/Credential")) {
        new-item sqlite:/Credential -key text not null -username text not null -password text not null -id integer primary key | Out-Null
    }
}

Init-SQLite
