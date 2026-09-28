final: prev: {
  alzlibtool = prev.buildGoModule rec {
    pname = "alzlibtool";
    version = "0.32.0";

    src = prev.fetchFromGitHub {
      owner = "Azure";
      repo = "alzlib";
      rev = "v${version}";
      hash = "sha256-ZhR23jybiQU14AbFqzJ4Pqxpw7L4WYg3vpg0F84ga5Q=";
    };

    # Only build the CLI entrypoint, not the whole alzlib library/tests.
    subPackages = [ "cmd/alzlibtool" ];

    vendorHash = "sha256-tyjijiDJGQBqsl3nqGAredhOrKnxllqk6k2mBc2AfiA=";

    doCheck = false;

    meta = {
      description = "CLI tool for the Azure Landing Zones alzlib Go library (docs/policy generation, validation)";
      homepage = "https://github.com/Azure/alzlib/tree/main/cmd/alzlibtool";
      license = prev.lib.licenses.mit;
      mainProgram = "alzlibtool";
    };
  };
}
