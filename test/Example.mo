import { snafu; context } "../src/Snafu";
import Snafu "../src/Snafu";
import Array "mo:base2/Array";
import Text "mo:base2/Text";
import M "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import Suite "mo:matchers/Suite";

module {
  type SemVer = { major : Text; minor : Text; patch : Text };
  type RawDependency = { name : Text; version : Text };
  type RawPackage = RawDependency and {
    dependencies : [RawDependency];
  };
  type ValidatedDependency = { name : Text; version : SemVer };
  type ValidatedPackage = ValidatedDependency and {
    dependencies : [ValidatedDependency];
  };

  func validateSemver(version : Text) : Snafu.Result<SemVer> {
    let components = Array.fromIter(Text.split(version, #char '.'));
    if (components.size() != 3) {
      return #err(snafu("Invalid semantic version: '" # version # "'"));
    };
    #ok({
      major = components[0];
      minor = components[1];
      patch = components[2];
    });
  };

  func validateDependency(dependency : RawDependency) : Snafu.Result<ValidatedDependency> {
    if (dependency.name == "") {
      return #err(snafu("Empty package name"));
    };
    let version = switch (validateSemver(dependency.version)) {
      case (#ok(ok)) { ok };
      case (#err(err)) {
        return context(err, "Failed to validate package '" # dependency.name # "'");
      }
    };
    #ok({ name = dependency.name; version });
  };

  func validatePackage(package : RawPackage) : Snafu.Result<ValidatedPackage> {
    let pkg = switch (validateDependency(package)) {
      case (#err(err)) { return #err(err) };
      case (#ok(ok)) { ok };
    };
    let dependencies = switch (Array.mapResult(package.dependencies, validateDependency)) {
      case (#err(err)) {
        return context(err, "Failed to validate dependencies of package '" # package.name # "'")
      };
      case (#ok(ok)) { ok };
    };
    #ok({ pkg with dependencies });
  };

  func testPrint(res : Snafu.Result<Any>) : Text {
    switch (res) {
      case (#ok(_)) { "All good" };
      case (#err(snafu)) { Snafu.print(snafu) };
    };
  };

  public func suite() : Suite.Suite {
    Suite.suite(
      "Package validation",
      [
        Suite.test(
          "Succeeds on a valid package",
          testPrint(validatePackage({ name = "matchers"; version = "1.0.0"; dependencies = [] })),
          M.equals(T.text("All good")),
        ),
        Suite.test(
          "Fails to validate package name",
          testPrint(validatePackage({ name = ""; version = "1.0.0"; dependencies = [] })),
          M.equals(T.text("Error: Empty package name\n")),
        ),
        Suite.test(
          "Fails to validate package version",
          testPrint(validatePackage({ name = "matchers"; version = "1.0"; dependencies = [] })),
          M.equals(
            T.text(
              "Error: Failed to validate package 'matchers'
Caused by:
    Invalid semantic version: '1.0'
"
            )
          ),
        ),
        Suite.test(
          "Fails to validate dependency with empty name",
          testPrint(validatePackage({ name = "matchers"; version = "1.0.0"; dependencies = [{ name = ""; version = "0.3.1" }] })),
          M.equals(
            T.text(
              "Error: Failed to validate dependencies of package 'matchers'
Caused by:
    Empty package name
"
            )
          ),
        ),
        Suite.test(
          "Fails to validate dependency with invalid version",
          testPrint(validatePackage({ name = "matchers"; version = "1.0.0"; dependencies = [{ name = "json"; version = "0.3" }] })),
          M.equals(
            T.text(
              "Error: Failed to validate dependencies of package 'matchers'
Caused by:
    Failed to validate package 'json'
    Invalid semantic version: '0.3'
"
            )
          ),
        ),
      ],
    );
  };
};
