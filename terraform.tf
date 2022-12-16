variable "hostname" {
  default     = "nixlet"
  type        = string
  description = "what name should be given to instance?"
}

variable "vpc_name" {
  default     = "default"
  type        = string
  description = "name of the VPC to target, if \"default\" will be appended with -$region"
}

variable "ssh_key_ids" {
  default     = []
  type        = list(number)
  description = "ssh key ids to grant root ssh access. does not create them. if unspecified, all currently available ssh keys will be used (within the  project containing this API token)."
}

variable "volume_ids" {
  default     = []
  type        = list(number)
  description = "list of volumes to be mounted to the created droplet."
}

variable "region" {
  default     = "nyc3"
  type        = string
  description = "which digitalocean region should be used?"
}

variable "droplet_size" {
  default     = "s-1vcpu-1gb-intel"
  description = "which digitalocean droplet size should be used?"
  type        = string
}

variable "floating_ip" {
  default     = true
  type        = bool
  description = "reserve a floating IP droplet host?"
}

variable "ipv6" {
  default     = true
  type        = bool
  description = "enable ipv6?"
}

variable "nixos_config" {
  default     = ""
  type        = string
  description = "file contents of custom.nix (if empty, default will be used)"
}

variable "flake_config" {
  default     = ""
  type        = string
  description = "file contents of flake.nix (if empty, default will be generated)"
}

variable "infect_script" {
  default     = ""
  type        = string
  description = "file contents of infect.sh (if empty, default will be used)"
}

variable "nixos_system" {
  default = "x86_64-linux"
  type    = string
}

variable "nixos_channel" {
  default     = "nixos-unstable"
  type        = string
  description = "which nix channel should be used for managed hosts?"
}

variable "graceful_shutdown" {
  default     = false
  type        = bool
  description = "allow this droplet to shutdown gracefully?"
}

variable "backups" {
  default     = false
  type        = bool
  description = "enable regular digitalocean droplet backups"
}

variable "resize_disk" {
  default     = false
  type        = bool
  description = "resize disk when resizing the droplet (permanent change)"
}

variable "image" {
  default     = "debian-11-x64"
  description = "change this at your own risk. it \"just works\" like this..."
  type        = string
}

variable "droplet_tags" {
  default     = []
  description = "tags to apply to droplet."
  type        = list(string)
}

data "digitalocean_ssh_keys" "all" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

data "cloudinit_config" "user_data" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "bootstrap.yml"
    content_type = "text/cloud-config"
    content = yamlencode({

      # Create nix install group
      groups = ["nixbld"]

      # Create nix install users
      users = [
        for id in range(0, 9) : {
          name          = "nixbld${id}"
          no_user_group = true
          system        = true
          gecos         = "Nix build user ${id}"
          primary_group = "nixbld"
          groups        = ["nixbld"]
        }
      ]

      # Write nixos files
      write_files = [{
        path        = "/root/infect.sh"
        permissions = "0600"
        content     = var.infect_script != "" ? var.infect_script : file("${path.module}/infect.sh")
        }, {
        path        = "/etc/nixos/flake.nix"
        permissions = "0644"
        content     = var.flake_config != "" ? var.flake_config : <<-DEFAULT_FLAKE
        {
          description = "${var.hostname}";

          inputs = {
            nixpkgs.url = "nixpkgs/${var.nixos_channel}";
          };

          outputs = {
            self,
            nixpkgs,
          }@inputs': {
            nixosConfigurations."${var.hostname}" = nixpkgs.lib.nixosSystem rec {
              system = "${var.nixos_system}";
              specialArgs = inputs' // { inherit system; };
              modules = [(import ./configuration.nix)];
            };
          };
        }
        DEFAULT_FLAKE
        }, {
        path        = "/etc/nixos/custom.nix"
        permissions = "0644"
        content     = var.nixos_config != "" ? var.nixos_config : <<-DEFAULT_NIXOS_CONFIG
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
              alias.list-vars = "!$${lib.getExe pkgs.bat} -l=ini --file-name 'git var -l (sorted)' <(git var -l | sort)";
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
              credential."https://github.*".helper = "$${lib.getExe pkgs.gh} auth git-credential";
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
              interactive.difffilter = "$${lib.getExe pkgs.delta} --color-only";
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
        DEFAULT_NIXOS_CONFIG
        }, {
        # System-wide nix configuration
        path        = "/etc/nix/nix.conf"
        permissions = "0644"
        content     = <<-NIX_CONF
          allow-dirty = true
          allowed-users = root
          auto-optimise-store = true
          build-users-group = nixbld
          download-attempts = 3
          enforce-determinism = true
          eval-cache = true
          experimental-features = nix-command flakes ca-derivations
          http-connections = 50
          log-lines = 30
          system-features = kvm
          trusted-users = root
          warn-dirty = false
        NIX_CONF
      }]

      # Final bootstrapping
      runcmd = [
        "apt-get install -qqy jq",
        "env HOME=/root USER=root NIXOS_IMPORT=./custom.nix NIX_CHANNEL=${var.nixos_channel} bash /root/infect.sh 2>&1 | tee /tmp/infect.log",
      ]
    })
  }
}

data "digitalocean_vpc" "main" {
  name = var.vpc_name == "default" ? "default-${var.region}" : var.vpc_name
}

resource "digitalocean_droplet" "main" {
  backups           = var.backups
  droplet_agent     = false
  graceful_shutdown = var.graceful_shutdown
  image             = var.image
  ipv6              = var.ipv6
  monitoring        = false
  name              = var.hostname
  region            = var.region
  resize_disk       = var.resize_disk
  size              = var.droplet_size
  ssh_keys          = length(var.ssh_key_ids) != 0 ? var.ssh_key_ids : data.digitalocean_ssh_keys.all.ssh_keys.*.id
  tags              = length(var.droplet_tags) != 0 ? var.droplet_tags : ["nixos"]
  user_data         = data.cloudinit_config.user_data.rendered
  volume_ids        = var.volume_ids
  vpc_uuid          = data.digitalocean_vpc.main.id
  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "digitalocean_floating_ip" "main" {
  count      = var.floating_ip ? 1 : 0
  droplet_id = digitalocean_droplet.main.id
  region     = digitalocean_droplet.main.region
}

locals {
  ssh_username = "root"
  ipv4_address = var.floating_ip ? digitalocean_floating_ip.main[0].ip_address : digitalocean_droplet.main.ipv4_address
}

output "ipv4_address" {
  value       = local.ipv4_address
  description = "public ipv4 address"
}

output "ipv6_address" {
  value       = digitalocean_droplet.main.ipv6_address
  description = "public ipv6 address"
}

output "floating_ip" {
  description = "(augmented) floating_ip resource"
  value = !var.floating_ip ? {} : merge(digitalocean_floating_ip.main[0], {
  })
}

output "droplet" {
  description = "(augmented) droplet resource"
  value = merge(digitalocean_droplet.main, {
    ssh_command  = format("ssh %s@%s", local.ssh_username, local.ipv4_address)
    ssh_username = "root"
  })
}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2"
    }
  }
}
