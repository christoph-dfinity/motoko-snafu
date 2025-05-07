# snafu

This library provides an easy to use Error type for idiomatic error handling in Motoko applications.

## Installing

```toml
[dependencies]
snafu = "0.1.1"
```

## Usage

Use `Snafu.Result<T>` as the return type for functions that can fail.

```motoko
import Snafu "mo:snafu/Snafu";

func registerUsername(name : Text) : Snafu.Result<Nat> {
  if (name == "") {
    return Snafu.snafu("Invalid empty name")
  };
  if (users.contains(name)) {
    return Snafu.snafu("Name already taken")
  };
  users.add(name);
  return #ok(users.size());
};
```

Add additional context to existing errors, to make it easier to troubleshoot when things go wrong.

```motoko
  let userId = registerUsername("") |> (switch _ {
    case (#ok ok) ok;
    case (#err err)
      return Snafu.context(err, "Failed to create User")
  });
  ...
```

Before returning from an Actor pretty print the error, choosing the right level of detail.


```motoko
import Snafu "mo:snafu/Snafu";
import Result "mo:base/Result";
actor {
  func registerUser() async Result.Result<UserId, Text> {
    register() |> Snafu.pretty()
    // #err("Failed to create User")

    register() |> Snafu.prettyTrace()
    // #err(
    // "Error: Failed to create User
    //  Caused by:
    //      Invalid empty name
    // ")
  }
}
```

Check out test/Example.mo for a slightly more involved example.


## Attribution

Lots of inspiration for this library was taken from using the [anyhow Rust crate](https://crates.io/crates/anyhow).
