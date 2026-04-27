{
  config,
  lib,
  ...
}:
let
  cfg = config.hardened-services;

  # Derive service names from filenames in ./services/
  serviceDir = builtins.readDir ./services;
  serviceNames = map (f: lib.removeSuffix ".nix" f) (builtins.attrNames serviceDir);

  # Wrap a value in mkOverride 75 (wins over upstream defaults at 100,
  # but loses to mkForce at 50). Skip values already wrapped by the
  # module system (e.g. mkForce).
  hardenPriority = v: if builtins.isAttrs v && v ? _type then v else lib.mkOverride 75 v;

  # Import a service file and apply hardening priority to its serviceConfig values
  mkHardenedService =
    name:
    let
      raw = (import ./services/${name}.nix) { inherit lib; };
      svcAttrs = raw.systemd.services;
      svcName = builtins.head (builtins.attrNames svcAttrs);
      rawConfig = svcAttrs.${svcName}.serviceConfig;
    in
    lib.mkIf cfg.services.${name}.enable {
      systemd.services.${svcName}.serviceConfig = lib.mapAttrs (_: hardenPriority) rawConfig;
    };
in
{
  options.hardened-services = {
    enable = lib.mkEnableOption "systemd service hardening";

    services = lib.mkOption {
      description = "Per-service hardening toggles. All default to enabled when hardened-services.enable is true.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to apply hardening to this service.";
          };
        }
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Auto-populate services options for all known service files
      { hardened-services.services = lib.genAttrs serviceNames (_: { }); }
      # Apply hardening for each enabled service
      (lib.mkMerge (map mkHardenedService serviceNames))
    ]
  );
}
