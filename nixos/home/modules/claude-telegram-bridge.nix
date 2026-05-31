{ pkgs, config, lib, ... }:

let
  cfg = config.services.claude-telegram-bridge;

  bridgeSrc = pkgs.fetchFromGitHub {
    owner = "FrancoMarcolongo";
    repo = "claude-telegram-bridge";
    rev = "dbed8a7da3572a5102aca4060dd1fefff384c59f";
    hash = "sha256-GIRyZ42hY3tiihsAIJvcNCMQJWUp8s2/CTiJxSh8n2M=";
  };

  stateRoot = "${config.xdg.dataHome}/claude-telegram-bridge-${cfg.name}";
  buildDir = "${stateRoot}/build";
  configDir = "${config.xdg.configHome}/claude-telegram-bridge-${cfg.name}";

  buildScript = pkgs.writeShellScript "claude-telegram-bridge-${cfg.name}-build" ''
    set -euo pipefail
    mkdir -p "${buildDir}"
    stamp="${stateRoot}/.src-stamp"
    if [ "$(cat "$stamp" 2>/dev/null || true)" != "${bridgeSrc}" ]; then
      ${pkgs.rsync}/bin/rsync -a --delete --exclude=node_modules "${bridgeSrc}/" "${buildDir}/"
      chmod -R u+w "${buildDir}"
      cd "${buildDir}"
      ${pkgs.nodejs_22}/bin/npm ci --prefer-offline --no-audit --fund=false
      ${pkgs.nodejs_22}/bin/npm run build
      echo "${bridgeSrc}" > "$stamp"
    fi
  '';

  yamlFormat = pkgs.formats.yaml { };
  configFile = yamlFormat.generate "claude-telegram-bridge-${cfg.name}-config.yaml" cfg.settings;
in
{
  options.services.claude-telegram-bridge = {
    enable = lib.mkEnableOption "Claude Telegram Bridge user service";

    name = lib.mkOption {
      type = lib.types.str;
      description = ''
        Instance name. Used as the systemd unit suffix
        (claude-telegram-bridge-<name>) and config/state dir suffix.
      '';
    };

    sopsFile = lib.mkOption {
      type = lib.types.path;
      default = ../../secrets/claude-telegram-bridge.yaml;
      description = "Sops-encrypted YAML file holding the bot token (and optional PIN).";
    };

    botTokenSecret = lib.mkOption {
      type = lib.types.str;
      description = "Key in sopsFile holding TELEGRAM_BOT_TOKEN.";
    };

    bridgePinSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional key in sopsFile holding BRIDGE_PIN.";
    };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      description = "Contents of the bridge's config.yaml, rendered via pkgs.formats.yaml.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.age.keyFile = lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    sops.secrets = {
      "${cfg.botTokenSecret}" = { sopsFile = cfg.sopsFile; };
    } // lib.optionalAttrs (cfg.bridgePinSecret != null) {
      "${cfg.bridgePinSecret}" = { sopsFile = cfg.sopsFile; };
    };

    sops.templates."claude-telegram-bridge-${cfg.name}.env" = {
      content = ''
        TELEGRAM_BOT_TOKEN=${config.sops.placeholder."${cfg.botTokenSecret}"}
      '' + lib.optionalString (cfg.bridgePinSecret != null) ''
        BRIDGE_PIN=${config.sops.placeholder."${cfg.bridgePinSecret}"}
      '';
      path = "${configDir}/.env";
    };

    xdg.configFile."claude-telegram-bridge-${cfg.name}/config.yaml".source = configFile;

    systemd.user.services."claude-telegram-bridge-${cfg.name}" = {
      Unit = {
        Description = "Claude Telegram Bridge (${cfg.name})";
        After = [ "network-online.target" "sops-nix.service" ];
        Wants = [ "network-online.target" ];
        Requires = [ "sops-nix.service" ];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = configDir;
        Environment = [
          "PATH=${pkgs.openai-whisper}/bin:${pkgs.ffmpeg}/bin:${config.home.profileDirectory}/bin:/usr/bin:/bin"
        ];
        ExecStartPre = "${buildScript}";
        ExecStart = "${pkgs.nodejs_22}/bin/node ${buildDir}/dist/index.js";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStartSec = "10min";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
