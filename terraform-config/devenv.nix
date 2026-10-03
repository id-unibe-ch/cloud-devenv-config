{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
# Disable python3-ecdsa test which fail in container.
#
# The library is used by checkov.
let
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
in
{
  packages = [
    pkgs.trivy
    checkov
    pkgs.terraform-docs
    pkgs.check-jsonschema
    pkgs.tflint
    pkgs.tf-summarize
    pkgs.marksman
  ];

  languages.terraform = {
    enable = true;
    version = "1.15.9";
  };

  devcontainer.enable = true;

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
      entry = "terraform validate";
      files = "\\.(tf|tofu)$";
      pass_filenames = false;
      require_serial = true;
    };

    tflint = {
      enable = true;
      name = "TFLint";
      entry = "tflint";
      files = "\.(tf|tofu)$";
      excludes = [ "\.terraform/.*$" ];
      language = "system";
      pass_filenames = false;
    };
    checkov = {
      enable = true;
      name = "Checkov";
      entry = "checkov";
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
      entry = "trivy conf . --exit-code=1";
      files = "\.(tf|tofu|tfvars)$";
      language = "system";
      require_serial = true;
      pass_filenames = false;
    };
    terraform-docs = {
      enable = true;
      name = "terraform-docs";
      language = "system";
      entry = "terraform-docs";
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
    check-schema = {
      enable = true;
      name = "Check JSON Schema for Application Configs";
      entry = "check-jsonschema";
      language = "system";
      files = "^apps/.*\.yaml$";
      args = [
        "--schemafile"
        "./apps/schema_application.json"
      ];
    };
  };
}
