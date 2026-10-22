{ pkgs, multiverse, ... }:
let
  # Disable python3-ecdsa test which fail in container.
  #
  # The library is used by checkov.
  ecdsa = pkgs.python3Packages.ecdsa.overridePythonAttrs (oldAttrs: {
    disabledTests = (oldAttrs.disabledTests or [ ]) ++ [
      "test_multithreading_with_interrupts"
    ];
  });

  checkov = multiverse.checkov."3.3.9".overridePythonAttrs (oldAttrs: {
    dependencies = map (
      dependency: if (dependency.pname or null) == "ecdsa" then ecdsa else dependency
    ) oldAttrs.dependencies;
  });

  checkJsonschema = multiverse.check-jsonschema."0.38.0";
  marksman = multiverse.marksman."2026-02-08";
  terraform = multiverse.terraform."1.15.9";
  terraformDocs = multiverse.terraform-docs."0.24.0";
  tflint = multiverse.tflint."0.64.0";
  tfSummarize = multiverse.tf-summarize."0.3.20";
  trivy = multiverse.trivy."0.76.0";
  vscodeJsonLanguageserver = multiverse.vscode-json-languageserver."1.138.0";
  yamlLanguageServer = multiverse.yaml-language-server."1.25.0";
in
{
  packages = [
    checkov
    checkJsonschema
    marksman
    terraform
    terraformDocs
    tflint
    tfSummarize
    trivy
    vscodeJsonLanguageserver
    yamlLanguageServer
  ];

  languages.terraform = {
    enable = true;
    package = terraform;
  };

  devcontainer.enable = true;

  # Create symlink to pinned configuration files
  files.".terraform-docs.yml".text = builtins.readFile ./.terraform-docs.yml;
  files.".tflint.hcl".text = builtins.readFile ./.tflint.hcl;
  files."trivy.yaml".text = builtins.readFile ./trivy.yaml;

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
      entry = "${terraform}/bin/terraform";
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
      entry = "${trivy}/bin/trivy";
      args = [
        "-c"
        "trivy.yaml"
        "config"
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
      entry = "${terraformDocs}/bin/terraform-docs";
      args = [
        "-c"
        "./.terraform-docs.yml"
        "."
      ];
      pass_filenames = false;
      types_or = [
        "terraform"
        "markdown"
      ];
    };
  };
}
