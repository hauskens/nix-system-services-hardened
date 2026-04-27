# nix-system-services-hardened

A NixOS module that applies systemd service hardening to common system services, reducing their exposure scores as measured by `systemd-analyze security`.

Forked from [wallago/nix-system-services-hardened](https://github.com/wallago/nix-system-services-hardened) and converted into a NixOS module with per-service toggles and NixOS VM tests.

## Usage

Add the flake as an input and import the module:

```nix
# flake.nix
{
  inputs.nix-system-services-hardened.url = "github:hauskens/nix-system-services-hardened";

  outputs = { self, nixpkgs, nix-system-services-hardened, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        nix-system-services-hardened.nixosModules.default
        {
          hardened-services.enable = true;
        }
      ];
    };
  };
}
```

All supported services are hardened by default when `hardened-services.enable = true`. To disable hardening for a specific service:

```nix
{
  hardened-services.enable = true;
  hardened-services.services.docker.enable = false;
}
```

Hardening values use `mkOverride 75`, so they win over upstream defaults (priority 100) but yield to `mkForce` (priority 50).


## Development

```sh
nix develop          # enter dev shell
just check           # run flake checks (includes NixOS VM tests)
just fmt             # format all files
just new <service>   # scaffold a new service from template
just list            # list all hardened services
```

## Disclaimer

Some code has been made with assistance of LLM, tested by a human.

## License

Apache License - see the [LICENSE](LICENSE) file for details.
