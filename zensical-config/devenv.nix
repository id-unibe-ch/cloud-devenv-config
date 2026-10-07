{ pkgs, ... }:
{
  devcontainer.enable = true;

  packages = [
    pkgs.marksman
  ];

  # Create symlink to pinned markdownlint configuration file
  files.".markdownlint.yaml".text = builtins.readFile ./.markdownlint.yaml;

  languages.python = {
    enable = true;
    venv = {
      enable = true;
      requirements = ./requirements.txt;
    };
  };

  git-hooks.hooks = {
    check-added-large-files.enable = true;
    check-executables-have-shebangs.enable = true;
    check-merge-conflicts.enable = true;
    check-yaml.enable = true;
    detect-private-keys.enable = true;
    shellcheck.enable = true;
    markdownlint = {
      enable = true;
      entry = "${pkgs.markdownlint-cli}/bin/markdownlint -c ${./.markdownlint.yaml}";
    };
    mixed-line-endings = {
      enable = true;
      args = [
        "--fix=no"
      ];
    };
    trim-trailing-whitespace = {
      enable = true;
      args = ["--markdown-linebreak-ext=md"];
    };
  };
}
