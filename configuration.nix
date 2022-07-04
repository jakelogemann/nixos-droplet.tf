{
  config,
  lib,
  options,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    (_: with builtins; fromTOML (readFile ./generated.toml))
  ];

  boot.cleanTmpDir = true;
  environment.systemPackages = with pkgs; [vim];
  services.openssh.enable = true;
  users.users.root.initialPassword = "";
  users.users.root.openssh.authorizedKeys.keys = ["ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABySeaOu0G1iaMa5HLZVUrtd4WDqqzE+0Wt9QTsHqf/oAAeOLzY8he5/IR/Fymjsf3dUvC9k1Ye4BhBWLwt18JDZAAFdNA8zHmQWXoxSNKqhfj1elZkdr1s4iHQYCtIi5DqVY/l+m8GIVU/XbWUojQroimTZAcbHQ54WdjPW2YPSxyEEQ== draven"];
}
