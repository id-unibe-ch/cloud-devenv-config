# mkdocs-config

## Usage

You have to add following structure to enable the shared configuration.

`devenv.yaml`

```yaml
# yaml-language-server: $schema=https://devenv.sh/devenv.schema.json
imports:
  - cloud-config

nixpkgs:
  allow_unfree: true

inputs:
  cloud-config:
    url: github:id-unibe-ch/cloud-devenv-config?dir=mkdocs-config&ref=v1
    flake: false

  git-hooks:
    url: github:cachix/git-hooks.nix
```

This example pins the shared configuration to a rolling tag (see [here](../README.md) for an explanation. If you want the latest version / another tag you can specify that with the `ref` url parameter.

The `devenv.nix` can be an empty configuration block or add greetings suggesting
to start the dev server:

`devenv.nix`

```nix
{ ... }:
{
  enterShell = ''
    echo Run \`mkdocs serve\` to start the local preview server
  '';
}
```
