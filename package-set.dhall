let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

in [
    { name = "std"
    , version = "main"
    , repo = "https://github.com/internet-computer/std"
    , dependencies = [] : List Text
    },
    { name = "base"
    , version = "master-moc-0.6.28"
    , repo = "https://github.com/dfinity/motoko-base"
    , dependencies = [] : List Text
    },
] : List Package