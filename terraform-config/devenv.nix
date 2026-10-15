{ pkgs, ... }:
let
  # Disable python3-ecdsa test which fail in container.
  #
  # The library is used by checkov.
  ecdsa = pkgs.python3Packages.ecdsa.overridePythonAttrs (oldAttrs: {
    disabledTests = (oldAttrs.disabledTests or [ ]) ++ [
      "test_multithreading_with_interrupts"
    ];
  });
  checkov = pkgs.checkov.overridePythonAttrs (oldAttrs: {
    dependencies = map (
      dependency: if (dependency.pname or null) == "ecdsa" then ecdsa else dependency
    ) oldAttrs.dependencies;
  });

  # Pin tflint to a specific version independent of nixpkgs.
  tflintFromSource = pkgs.tflint.overrideAttrs (finalAttrs: oldAttrs: {
    version = "0.64.0";
    src = pkgs.fetchFromGitHub {
      owner = "terraform-linters";
      repo = "tflint";
      tag = "v${finalAttrs.version}";
      hash = "sha256-5ure5MysZsMcie75ox3gWEETqhor8wRqylQweuDu1qQ=";
    };
    vendorHash = "sha256-o59/JqIywhqKMkcyq/r1XRE9ldk/dE2v3Qj9IXq0G8s=";
  });

  tflintPkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/55ba7f49ef2962b42cbd126522b7df5f95037679.tar.gz";
    sha256 = "1c84q65az45wzfqcnhjw20rv46mi20a0qp7s7xgxdff9amr86vmj";
  }) { system = pkgs.stdenv.system; };
  tflintFromNixpkgs = tflintPkgs.tflint;

  tflint = tflintFromSource;
in
{
  packages = [
    pkgs.trivy
    checkov
    pkgs.terraform-docs
    pkgs.check-jsonschema
    tflint
    pkgs.tf-summarize
    pkgs.marksman
    pkgs.yaml-language-server
    pkgs.vscode-json-languageserver
  ];

  languages.terraform = {
    enable = true;
    version = "1.15.9";
  };

  devcontainer.enable = true;

  # Create symlink to pinned configuration files
  files.".terraform-docs.yml".text = builtins.readFile ./.terraform-docs.yml;
  files.".tflint.hcl".text = builtins.readFile ./.tflint.hcl;

  tasks."terraform:init" = {
    exec = "terraform init -backend=false";
    before = [ "devenv:enterShell" ];
    status = "ls .terraform";
  };

  tasks."tflint:init" = {
    exec = "tflint --init";
    before = [ "devenv:enterShell" ];
    after = [ "terraform:init" ];
    execIfModified = [
      ".tflint.hcl"
    ];
  };

  tasks."devenv:git-hooks:run".after = [
    "terraform:init"
    "tflint:init"
  ];

  git-hooks.hooks = {
    trim-trailing-whitespace.enable = true;
    check-added-large-files.enable = true;
    shellcheck.enable = true;
    check-json.enable = true;
    check-yaml.enable = true;
    check-toml.enable = true;
    check-executables-have-shebangs.enable = true;
    terraform-format.enable = true;

    terraform-validate-root = {
      enable = true;
      name = "Terraform validate (root module)";
      entry = "${pkgs.terraform}/bin/terraform";
      args = [ "validate" ];
      files = "\\.(tf|tofu)$";
      pass_filenames = false;
      require_serial = true;
    };

    tflint = {
      enable = true;
      name = "TFLint";
      entry = "${tflint}/bin/tflint";
      files = "\.(tf|tofu)$";
      excludes = [ "\.terraform/.*$" ];
      language = "system";
      pass_filenames = false;
    };

    checkov = {
      enable = true;
      name = "Checkov";
      entry = "${checkov}/bin/checkov";
      args = [
        "--framework"
        "terraform"
        "-d"
        "."
      ];
      files = "\.(tf|tofu)$";
      excludes = [ "\.terraform/.*$" ];
      language = "system";
      require_serial = true;
      pass_filenames = false;
    };

    trivy = {
      enable = true;
      name = "Trivy";
      entry = "${pkgs.trivy}/bin/trivy";
      args = [
        "conf"
        "."
        "--exit-code=1"
      ];
      files = "\.(tf|tofu|tfvars)$";
      language = "system";
      require_serial = true;
      pass_filenames = false;
    };

    terraform-docs = {
      enable = true;
      name = "terraform-docs";
      language = "system";
      entry = "${pkgs.terraform-docs}/bin/terraform-docs";
      args = [
        "-c"
        "./.terraform-docs.yml"
        "."
      ];
      pass_filenames = false;
      types = [
        "terraform"
        "markdown"
      ];
    };
  };
}
