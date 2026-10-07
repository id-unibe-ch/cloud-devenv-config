# cloud-azure-devenv-config

This repository contains shared [devenv.sh](https://devenv.sh) configuration which are used by the cloud team within [id-unibe-ch](https://github.com/id-unibe-ch).

Following base configurations are provided:

- [Terraform](/terraform-config/README.md)
- [Zensical](/zensical-config/README.md) for projects managing documentation based on Zensical static code generator

## Usage

Please see the referenced base configurations how to reference them in the `devenv.nix` and `devenv.yaml`.

> [!IMPORTANT]
> The shared configuration is stored within the `devenv.lock` file. If you want to update to a newer version of the central configuration, you'll have to run `devenv update`.

> [!TIP]
> To provide a stable reference, it is adviced to use a tag instead of referencing the `main` branch. This repository provides tags in semver notation and a rolling tag (e.g. v1 for version v1.x.x). 

### Binary Caches

The cloud team uses cachix with an individual binary cache, which can be used to speed up build times. But it is purposly not enabled by default within devenv. Instead you have to configure the nix system to use it by purpose.

Following step-by-step guide helps to enable the binary cache on the local machine: [Using a binary cache](https://nixos.wiki/wiki/Binary_Cache#Using_a_binary_cache).

For access to an api key contact the cloud team.
