{
  pkgs,
  lib,
}:
let
  # Per-service maximum allowed exposure score
  # Run `systemd-analyze security <service>` to see current scores.
  serviceThresholds = {
    accounts-daemon = 3.5;
    acpid = 5.0;
    auditd = 4.5;
    autovt = 5.0;
    blocky = 5.0;
    bluetooth = 5.0;
    colord = 5.0;
    cups = 5.0;
    dbus = 5.0;
    display-manager = 5.0;
    docker = 5.0;
    getty = 5.0;
    NetworkManager-dispatcher = 4.0;
    NetworkManager = 5.0;
    nix-daemon = 5.0;
    nscd = 5.0;
    reload-systemd-vconsole-setup = 5.0;
    rescue = 5.0;
    rtkit = 4.0;
    sshd = 5.0;
    systemd-ask-password-console = 5.0;
    systemd-ask-password-wall = 5.0;
    systemd-journald = 5.0;
    systemd-machined = 4.0;
    systemd-rfkill = 5.0;
    systemd-udevd = 5.0;
    user = 5.0;
    wpa_supplicant = 3.5;
  };

  # The systemd unit name can differ from the filename
  # (e.g. acpid.nix hardens acpid.service, user.nix hardens user@1000.service)
  unitName = {
    acpid = "acpid";
    user = "user@1000";
    getty = "getty@tty1";
    autovt = "autovt@tty1";
    rtkit = "rtkit-daemon";
    dbus = "dbus-broker";
    wpa_supplicant = "wpa_supplicant-wlan0";
  };

  # Build the per-service check snippet for the test script
  mkCheck =
    name: maxExposure:
    let
      unit = "${unitName.${name} or name}.service";
    in
    ''
      score_line = machine.succeed(
        "systemd-analyze security ${unit} --no-pager 2>&1"
        " | grep 'Overall exposure' || true"
      ).strip()

      if score_line:
        score = float(score_line.split(":")[1].strip().split()[0])
        if score > ${toString maxExposure}:
          failures.append(
            f"${unit}: exposure {score} exceeds max ${toString maxExposure}"
          )
          print(f"FAIL: ${unit} exposure {score} > ${toString maxExposure}")
        else:
          print(f"PASS: ${unit} exposure {score} <= ${toString maxExposure}")
      else:
        print("SKIP: ${unit} not found or not running")
    '';

  checkSnippets = lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs mkCheck serviceThresholds));
in
{
  all-services = pkgs.testers.nixosTest {
    name = "hardened-all-services";

    nodes.machine =
      { ... }:
      {
        imports = [ ../default.nix ];
        hardened-services.enable = true;

        # Enable services that aren't present in a minimal VM by default
        services.accounts-daemon.enable = true;
        services.acpid.enable = true;
        security.auditd.enable = true;
        services.blocky.enable = true;
        hardware.bluetooth.enable = true;
        services.colord.enable = true;
        services.printing.enable = true;
        services.xserver.enable = true;
        services.xserver.displayManager.lightdm.enable = true;
        virtualisation.docker.enable = true;
        networking.networkmanager.enable = true;
        security.rtkit.enable = true;
        services.openssh.enable = true;
        networking.wireless.enable = true;

        # networking.wireless and networkmanager conflict by default
        networking.wireless.interfaces = [ "wlan0" ];
      };

    testScript = ''
      machine.wait_for_unit("multi-user.target")

      failures = []

      ${checkSnippets}

      if failures:
        raise Exception(
          f"{len(failures)} service(s) exceeded threshold:\n"
          + "\n".join(failures)
        )
      print("All checks passed.")
    '';
  };

  greetd = pkgs.testers.nixosTest {
    name = "hardened-greetd";

    nodes.machine =
      { ... }:
      {
        imports = [ ../default.nix ];
        hardened-services.enable = true;

        services.greetd.enable = true;
      };

    testScript = ''
      machine.wait_for_unit("multi-user.target")

      failures = []

      score_line = machine.succeed(
        "systemd-analyze security greetd.service --no-pager 2>&1"
        " | grep 'Overall exposure' || true"
      ).strip()

      if score_line:
        score = float(score_line.split(":")[1].strip().split()[0])
        if score > 5.0:
          failures.append(
            f"greetd.service: exposure {score} exceeds max 5.0"
          )
          print(f"FAIL: greetd.service exposure {score} > 5.0")
        else:
          print(f"PASS: greetd.service exposure {score} <= 5.0")
      else:
        print("SKIP: greetd.service not found or not running")

      if failures:
        raise Exception(
          f"{len(failures)} service(s) exceeded threshold:\n"
          + "\n".join(failures)
        )
      print("All checks passed.")
    '';
  };
}
