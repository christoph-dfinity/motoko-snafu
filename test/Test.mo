import M "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import Suite "mo:matchers/Suite";
import Snafu "../src/Snafu";
import Int "mo:base2/Int";

func print(res: Snafu.Result<Any>): Text {
  switch (res) {
    case(#ok(_)) "All good";
    case(#err(snafu)) Snafu.print(snafu);
  }
};

type StructuredError = {
  code : Nat;
  path : Text;
};


type ApiError = {
  #invalidParam : Text;
};

type DBError = {
  #unknownCollection : { collection : Text };
};

type Params = {
  collection : ?Text;
};

func collectionCount(params : Params) : Snafu.Result<Nat> {
  let ?collection = params.collection else {
    return Snafu.snafuS("Missing collection", func() = to_candid(#invalidParam("Missing collection")))
  };
  switch collection {
    case "notes" { #ok(20) };
    case c { Snafu.snafuS("Unknown collection" # c, func() = to_candid(#unknownCollection({ collection = c }))) }
  };
};

let suite =
  Suite.suite("Snafu tests", [
    Suite.test("Simple error",
      print(Snafu.snafu("Oh noez")),
      M.equals(T.text("Error: Oh noez\n"))
    ),
    Suite.test("Nested error",
      print(Snafu.snafu("Oh noez") |> Snafu.context(_, "Well fuck")),
      M.equals(T.text("Error: Well fuck\nCaused by:\n    Oh noez\n"))
    ),
    Suite.test("Structured error",
      do? {
        let #err(err) = Snafu.snafuS("Oh noez", func () { to_candid({ code = 10; path = "well/dude" }) }) else {
          null!
        };
        let downCasted: ?StructuredError = from_candid(err.errCandid!());
        "Code: " # Int.toText(downCasted!.code) # " at: " # downCasted!.path
      },
      M.equals(T.optional(T.textTestable, ?"Code: 10 at: well/dude"))
    ),
    Suite.suite("Downcasting", [
      Suite.test("Without source",
        do {
          let #err(result) = collectionCount({ collection = null });
          Snafu.is<ApiError>(result, func (blob) = from_candid blob)
        },
        M.equals(T.bool(true)),
      ),
      Suite.test("Without source",
        do {
          let #err(result) = collectionCount({ collection = null });
          Snafu.is<DBError>(result, func (blob) = from_candid blob)
        },
        M.equals(T.bool(false)),
      ),
      Suite.test("Without source",
        do {
          let #err(result) = collectionCount({ collection = ?"cars" });
          Snafu.is<DBError>(result, func (blob) = from_candid blob)
        },
        M.equals(T.bool(true)),
      ),
    ])
  ]);
Suite.run(suite);
