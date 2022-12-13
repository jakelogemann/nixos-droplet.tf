{
  modulesPath,
  config,
  lib,
  options,
  pkgs,
  ...
}: {

  boot.cleanTmpDir = true;
  boot.kernel.sysctl."kernel.dmesg_restrict" = 1;
  boot.kernel.sysctl."kernel.kptr_restrict" = 2;
  boot.kernel.sysctl."kernel.perf_event_paranoid" = 1;
  boot.kernel.sysctl."kernel.randomize_va_space" = 2;
  boot.kernel.sysctl."kernel.sysrq" = 0;
  boot.kernel.sysctl."kernel.unprivileged_bpf_disabled" = 1;
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  boot.loader.grub.configurationLimit = 10;
  environment.variables.EDITOR = "vim";
  environment.variables.PAGER = "bat";
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";
  nix.daemonIOSchedPriority = 5;
  nix.gc.automatic = true;
  nix.gc.dates = "daily";
  nix.optimise.automatic = true;
  nix.optimise.dates = ["daily"];
  nix.settings.allow-dirty = true;
  nix.settings.auto-optimise-store = true;
  nix.settings.cores = 0;
  nix.settings.enforce-determinism = true;
  nix.settings.experimental-features = ["nix-command" "flakes" "ca-derivations"];
  nix.settings.extra-substituters = [];
  nix.settings.extra-trusted-public-keys = [];
  nix.settings.log-lines = 50;
  nix.settings.max-free = 64 * 1024 * 1024 * 1024;
  nix.settings.stalled-download-timeout = 90;
  nix.settings.system-features = ["kvm"];
  nix.settings.warn-dirty = false;
  nixpkgs.config.allowUnfree = true;
  programs.ssh.forwardX11 = false;
  programs.ssh.setXAuthLocation = false;
  programs.ssh.startAgent = false;
  security.lockKernelModules = true;
  security.protectKernelImage = true;
  security.rtkit.enable = true;
  services.do-agent.enable = true;
  services.journald.extraConfig = builtins.concatStringsSep "\n" ["SystemMaxUse=1G"];
  services.journald.forwardToSyslog = false;
  services.openssh.enable = true;
  services.openssh.kbdInteractiveAuthentication = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.ports = [22];
  services.sshguard.attack_threshold = 10;
  services.sshguard.blacklist_threshold = 20;
  services.sshguard.blocktime = 3600;
  services.sshguard.detection_time = 3600;
  services.sshguard.enable = true;
  services.sshguard.services = ["ssh"];
  system.autoUpgrade.enable = true;
  system.autoUpgrade.flags = lib.mkForce [];
  system.stateVersion = "22.11";
  systemd.services.sshd.serviceConfig.Slice = "ssh.slice";
  systemd.services.sshguard.serviceConfig.Slice = "ssh.slice";
  systemd.slices.ssh.enable = true;
  environment.defaultPackages = with pkgs; [
    (writeShellScriptBin "nixos-repl" "exec nix repl --quiet --offline --impure --no-write-lock-file --file '<nixpkgs/nixos>' \"$@\"")
    alejandra
    bat
    dmidecode
    dnsutils
    gh
    hddtemp
    ipmitool
    jq
    killall
    lsb-release
    lsd
    lsof
    lynis
    pinentry
    pstree
    psutils
    ripgrep
    tree
    usbutils
    vim
    whois
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      alias.aliases = "config --show-scope --get-regexp alias";
      alias.amend = "commit --amend";
      alias.amendall = "commit --amend --all";
      alias.amendit = "commit --amend --no-edit";
      alias.branches = "branch --all";
      alias.current-branch = "rev-parse --abbrev-ref HEAD";
      alias.l = "log --pretty=oneline --graph --abbrev-commit";
      alias.list-skipped = "!git ls-files -v | grep \"^S\" | cut -c3-";
      alias.list-vars = "!${lib.getExe pkgs.bat} -l=ini --file-name 'git var -l (sorted)' <(git var -l | sort)";
      alias.quick-rebase = "rebase --interactive --root --autosquash --autostash";
      alias.remotes = "remote --verbose";
      alias.repo-root = "rev-parse --show-toplevel";
      alias.show-config = "config --show-scope --show-origin --list --includes";
      alias.skip = "update-index --skip-worktree";
      alias.undo-commit = "reset --hard ORIG_HEAD";
      alias.unskip = "update-index --no-skip-worktree";
      alias.unstage = "restore --staged";
      alias.user = "config --show-scope --get-regexp user";
      apply.whitespace = "fix";
      branch.sort = "-committerdate";
      color.branch.current = "yellow bold";
      color.branch.local = "green bold";
      color.branch.remote = "cyan bold";
      color.diff.frag = "magenta bold";
      color.diff.meta = "yellow bold";
      color.diff.new = "green bold";
      color.diff.old = "red bold";
      color.diff.whitespace = "red reverse";
      color.status.added = "green bold";
      color.status.changed = "yellow bold";
      color.status.untracked = "red bold";
      color.ui = "auto";
      core.ignorecase = true;
      core.pager = lib.getExe pkgs.delta;
      core.untrackedcache = true;
      credential."https://github.*".helper = "${lib.getExe pkgs.gh} auth git-credential";
      delta.decorations.minus-style = "red bold normal";
      delta.decorations.plus-style = "green bold normal";
      delta.decorations.minus-emph-style = "white bold red";
      delta.decorations.minus-non-emph-style = "red bold normal";
      delta.decorations.plus-emph-style = "white bold green";
      delta.decorations.plus-non-emph-style = "green bold normal";
      delta.decorations.file-style = "yellow bold none";
      delta.decorations.file-decoration-style = "yellow box";
      delta.decorations.hunk-header-style = "magenta bold";
      delta.decorations.hunk-header-decoration-style = "magenta box";
      delta.decorations.minus-empty-line-marker-style = "normal normal";
      delta.decorations.plus-empty-line-marker-style = "normal normal";
      delta.decorations.line-numbers-right-format = "{np:^4}│ ";
      delta.features = "line-numbers decorations";
      delta.line-numbers = true;
      diff.bin.textconv = "hexdump -v -C";
      diff.renames = "copies";
      diff.tool = "vimdiff";
      help.autocorrect = 1;
      init.defaultbranch = "main";
      interactive.difffilter = "${lib.getExe pkgs.delta} --color-only";
      pull.ff = true;
      pull.rebase = true;
      push.default = "simple";
      push.followtags = true;
      rerere.autoupdate = true;
      rerere.enabled = true;

      core.excludesfile = builtins.toFile "git-excludes" (builtins.concatStringsSep "\n" [
        # Compiled
        "tags"
        "*.com"
        "*.class"
        "*.dll"
        "*.exe"
        "*.o"
        "*.so"
        # Editor's Temporary Files
        "*~"
        "*.swp"
        "*.swo"
        ".vscode"
        # Log files
        "*.log"
        ".nvimlog"
        # macOS-specific
        ".DS_Store*"
        "Icon?"
        "Thumbs.db"
        "ehthumbs.db"
        "*.dmg"
        # Archives
        "*.7z"
        "*.gz"
        "*.iso"
        "*.jar"
        "*.rar"
        "*.tar"
        "*.zip"
      ]);
    };
  };
}
