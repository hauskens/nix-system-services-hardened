# Originally forked from https://github.com/wallago/nix-system-services-hardened
# Changes should be downstreamed
{ ... }:
{
  systemd.services.systemd-journald.serviceConfig = {
    NoNewPrivileges = true;
    ProtectProc = "invisible";
    ProtectHostname = true;
    PrivateMounts = true;
  };
}
