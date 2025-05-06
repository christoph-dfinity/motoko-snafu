/// Snafu is a convenient Error type that accumulates context, and
/// makes it easy to report better errors
import Result "mo:new-base/Result";
import Iter "mo:new-base/Iter";
import Option "mo:new-base/Option";

module {
  /// A Snafu.Result is
  public type Result<A> = Result.Result<A, Snafu>;

  /// An Error type with context
  public type Snafu = {
    errCandid : ?(() -> Blob);
    toText : () -> Text;
    source : ?Snafu;
  };

  /// Constructs a Snafu
  public func mkSnafu(msg : Text) : Snafu =
    {
      errCandid = null;
      toText = func() : Text = msg;
      source = null;
    };

  /// Constructs a structured Error that can be reconstructed/checked via Snafu.as/is
  public func mkSnafuS(msg : Text, toCandid : () -> Blob) : Snafu =
    {
      errCandid = ?toCandid;
      toText = func() : Text = msg;
      source = null;
    };

  /// Constructs a Snafu Result
  public func snafu(msg : Text) : Result<None> = #err(mkSnafu(msg));

  /// Constructs a structured Snafu Result that can be reconstructed/checked via Snafu.as/is
  public func snafuS(msg : Text, toCandid : () -> Blob) : Result<None> =
    #err(mkSnafuS(msg, toCandid));

  /// Adds context to a given Snafu and wraps it in #err.
  public func context(source : Snafu, msg : Text) : Result<None> {
    #err({
      errCandid = null;
      toText = func() : Text = msg;
      source = ?source;
    });
  };

  /// Adds structured context to a given Snafu and wraps it in #err.
  public func contextS(
    source : Snafu,
    msg : Text,
    toCandid : () -> Blob
  ) : Result<None> {
    #err({
      errCandid = ?toCandid;
      toText = func() : Text = msg;
      source = ?source;
    });
  };

  /// Prints a Snafu including its context trace
  public func print(snafu : Snafu) : Text {
    var res = "Error: " # snafu.toText();
    var printedTraceHeader = false;
    for (source in stacktrace(snafu)) {
      if (not printedTraceHeader) {
        res #= "\nCaused by:";
        printedTraceHeader := true;
      };
      res #= "\n    " # source.toText();
    };
    res #= "\n";
    res;
  };

  /// Returns an iterator over all errors. Does include the top-level
  /// error
  public func errors(snafu : Snafu) : Iter.Iter<Snafu> {
    var current : ?Snafu = ?snafu;
    {
      next = func() : ?Snafu = do? {
        let tmp = current!;
        current := tmp.source;
        tmp;
      };
    };
  };

  /// Returns an iterator over all underlying errors.
  /// Does _not_ include the top-level error
  public func stacktrace(snafu : Snafu) : Iter.Iter<Snafu> {
    let iter = errors(snafu);
    ignore iter.next();
    iter
  };

  /// Tries down-casting the error or any of its sources to type A
  /// Expects a filter function that uses `from_candid`
  public func as<A>(snafu : Snafu, filter : Blob -> ?A) : ?A {
    Iter.filterMap(
      errors(snafu),
      func(s : Snafu) : ?A = switch (s.errCandid) {
        case (null) null;
        case (?f) filter(f());
      },
    ).next();
  };

  /// Checks if the error or any of its sources are of type A
  /// Expects a filter function that uses `from_candid`
  public func is<A>(snafu : Snafu, filter : Blob -> ?A) : Bool =
    Option.isSome(as<A>(snafu, filter));
};
