let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.14.7-20250404/package-set.dhall sha256:0736abae9f592074f74ec44995b5f352efc2fa7cb30f30746d3b0861a7d837c3
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  -- This is where you can add your own packages to the package-set
  additions =
    [ { name = "base2"
      , version = "1c362a913315580938dc4462bf87148b06a6095d"
      , repo = "https://github.com/dfinity/new-motoko-base"
      , dependencies = [] : List Text
      }
    ] : List Package

let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  upstream # additions # overrides
