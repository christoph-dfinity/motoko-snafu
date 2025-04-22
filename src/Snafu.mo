import Result "mo:base2/Result";
import Iter "mo:base2/Iter";
import Option "mo:base2/Option";

module {

  /// A convenience synonym
  public type Result<A> = Result.Result<A, Snafu>;

  public type Snafu = {
    errCandid : ?(() -> Blob);
    toText : () -> Text;
    source : ?Snafu;
  };

  public func mkSnafu(msg : Text) : Snafu =
    {
      errCandid = null;
      toText = func() : Text = msg;
      source = null;
    };

  /// Constructs a Snafu and immediately wraps it in #err
  public func snafu(msg : Text) : Result<None> = #err(mkSnafu(msg));

  /// Constructs a structured Error that can be reconstructed/checked via Snafu.as/is
  public func snafuS(msg : Text, toCandid : () -> Blob) : Result<None> = #err {
    errCandid = ?toCandid;
    toText = func() : Text = msg;
    source = null;
  };

  /// Wraps an incoming Result with extra context
  public func context<A>(res : Result<A>, msg : Text) : Result<A> {
    switch (res) {
      case (#ok(_)) res;
      case (#err(source)) #err {
        errCandid = null;
        toText = func() : Text = msg;
        source = ?source;
      };
    };
  };

  /// Wraps an incoming Result with extra structured context
  public func contextS<A>(res : Result<A>, msg : Text, toCandid : () -> Blob) : Result<A> {
    switch (res) {
      case (#ok(_)) res;
      case (#err(source)) #err {
        errCandid = ?toCandid;
        toText = func() : Text = msg;
        source = ?source;
      };
    };
  };

  public func fromOption<A>(res : ?A, msg : Text) : Result<A> {
    switch (res) {
      case (?a) #ok(a);
      case null #err {
        errCandid = null;
        toText = func() : Text = msg;
        source = null;
      };
    }
  };

  public func fromOptionS<A>(res : ?A, msg : Text, toCandid : () -> Blob) : Result<A> {
    switch (res) {
      case (?a) #ok(a);
      case (null) #err {
        errCandid = ?toCandid;
        toText = func() : Text = msg;
        source = null;
      };
    };
  };


  /// Prints a Snafu.Snafu
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

  /// Returns an iterator over all underlying errors. Does _not_ include the top-level error
  public func stacktrace(snafu : Snafu) : Iter.Iter<Snafu> {
    var current : ?Snafu = ?snafu;
    {
      next = func() : ?Snafu = do ? {
        current := current!.source;
        current!;
      };
    };
  };

  /// Tries down-casting the error or any of its sources to type A
  /// Expects a filter function that uses `from_candid`
  public func as<A>(snafu : Snafu, filter : Blob -> ?A) : ?A {
    ignore do ? {
      let candid = snafu.errCandid! ();
      let filtered = filter(candid)!;
      return ?filtered;
    };

    Iter.filterMap(
      stacktrace(snafu),
      func(s : Snafu) : ?A = switch (s.errCandid) {
        case null null;
        case (?f) filter(f());
      },
    ).next();
  };

  /// Checks if the error or any of its sources are of type A
  /// Expects a filter function that uses `from_candid`
  public func is<A>(snafu : Snafu, filter : Blob -> ?A) : Bool = Option.isSome(as<A>(snafu, filter));
};
