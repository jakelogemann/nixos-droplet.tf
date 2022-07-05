{
  modulesPath,
  config,
  lib,
  options,
  pkgs,
  ...
}: {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
    (_: with builtins; fromTOML (readFile ./generated.toml))
  ];

  services.do-agent.enable = true;
  networking.interfaces.eth0.useDHCP = true;
  networking.interfaces.eth1.useDHCP = true;
  networking.nameservers = ["8.8.8.8" "8.8.4.4"];
  networking.usePredictableInterfaceNames = lib.mkForce false;
  nix.settings.enforce-determinism = true;
  nix.settings.experimental-features = ["flakes" "nix-command"];
  services.openssh.enable = true;
  users.users.root.initialPassword = "p@ssW0Rd!%*";
  networking.useDHCP = true;

  boot = {
    loader.grub.device = "nodev";
    loader.efi.efiSysMountPoint = "/boot/efi";
    loader.efi.canTouchEfiVariables = true;
    kernelModules = ["nvme"];
    cleanTmpDir = true;
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  };

  environment = {
    shellAliases = {
      ga = "git add";
      gb = "git branch";
      gci = "git commit";
      gco = "git checkout";
      gd = "git diff";
      gf = "git fetch";
      gl = "git log";
      grb = "git rebase";
      grm = "git rm";
      gs = "git status -sb";
      gsw = "git switch";
    };
    variables.EDITOR = "vim";
    systemPackages = with pkgs; [
      (writeShellScriptBin "nixos-repl" "exec nix repl '<nixpkgs/nixos>'")
      alejandra
      bat
      vim
      delta
      direnv
      dogdns
      jq
      lsd
      navi
      ripgrep
      skim
      zoxide
    ];
  };
}
