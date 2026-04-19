{ pkgs, config, lib, ... }:

let
  upstreamSrc = pkgs.fetchFromGitHub {
    owner = "vrtmrz";
    repo = "livesync-bridge";
    rev = "95e8ce6d567e1b928a1c269711c5df1330f2727d";
    hash = "sha256-4HT5I2EsPVuO7OAJvVnYWy23jNIIIcpeADS1bWXT4+I=";
    fetchSubmodules = true;
  };

  # Upstream deno.jsonc references a broken `trystero` import URL
  # (github.com/vrtmrz/vrtmrz/trystero — typo, repo doesn't exist). It's only
  # used by the P2P replicator path; this daemon only uses couchdb + storage
  # peers, so we strip the entry to let `deno install` succeed.
  src = pkgs.runCommand "livesync-bridge-patched" { } ''
    mkdir -p $out
    cp -r ${upstreamSrc}/. $out/
    chmod -R u+w $out
    ${pkgs.gnused}/bin/sed -i '/"trystero":/d' $out/deno.jsonc
  '';

  stateDir   = "${config.xdg.dataHome}/livesync-bridge";
  configPath = "${config.xdg.configHome}/livesync-bridge/config.json";
  vaultDir   = "${config.home.homeDirectory}/Documents/ObsidianVault";

  prestart = pkgs.writeShellScript "livesync-bridge-prestart" ''
    set -euo pipefail

    mkdir -p "${stateDir}/run" "${stateDir}/deno" "${vaultDir}"

    stamp="${stateDir}/run/.src-stamp"
    if [ "$(cat "$stamp" 2>/dev/null || true)" != "${src}" ]; then
      ${pkgs.rsync}/bin/rsync -a --delete \
        --exclude=node_modules --exclude=.src-stamp \
        "${src}/" "${stateDir}/run/"
      chmod -R u+w "${stateDir}/run"
      cd "${stateDir}/run"
      ${pkgs.deno}/bin/deno install --allow-import
      echo "${src}" > "$stamp"
    fi
  '';
in
{
  home.packages = [ pkgs.deno ];

  home.activation.livesyncBridgeDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${stateDir}/run" "${stateDir}/deno" "${vaultDir}"
  '';

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/livesync-bridge.yaml;
    secrets.livesync_couchdb_password     = { key = "couchdb_password"; };
    secrets.livesync_passphrase           = { key = "livesync_passphrase"; };
    secrets.livesync_obfuscate_passphrase = { key = "livesync_obfuscate_passphrase"; };

    templates."livesync-bridge-config.json" = {
      content = builtins.toJSON {
        peers = [
          {
            type     = "couchdb";
            name     = "obsidian-remote";
            group    = "main";
            url      = "http://10.0.0.2:5984";
            database = "obsidian";
            username = "nacho692";
            password = config.sops.placeholder.livesync_couchdb_password;
            passphrase = config.sops.placeholder.livesync_passphrase;
            obfuscatePassphrase = config.sops.placeholder.livesync_obfuscate_passphrase;
            baseDir = "";
            useRemoteTweaks = true;
          }
          {
            type  = "storage";
            name  = "obsidian-local";
            group = "main";
            baseDir = "${vaultDir}/";
            scanOfflineChanges = true;
            useChokidar = false;
          }
        ];
      };
      path = configPath;
    };
  };

  systemd.user.services.livesync-bridge = {
    Unit = {
      Description = "Obsidian Self-Hosted LiveSync CouchDB <-> filesystem bridge";
      After = [ "network-online.target" "sops-nix.service" ];
      Wants = [ "network-online.target" ];
      Requires = [ "sops-nix.service" ];
    };
    Service = {
      Type = "simple";
      Environment = [
        "LSB_CONFIG=${configPath}"
        "DENO_DIR=${stateDir}/deno"
      ];
      WorkingDirectory = "${stateDir}/run";
      ExecStartPre = "${prestart}";
      ExecStart = "${pkgs.deno}/bin/deno task run";
      Restart = "on-failure";
      RestartSec = 30;
      TimeoutStartSec = "10min";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
