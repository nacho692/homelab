{ pkgs, config, lib, ... }:

let
  cfg = config.services.claude-telegram-bridge;

  bridgePkg = pkgs.buildNpmPackage {
    pname = "claude-telegram-bridge";
    version = "0-unstable-dbed8a7";
    src = pkgs.fetchFromGitHub {
      owner = "FrancoMarcolongo";
      repo = "claude-telegram-bridge";
      rev = "dbed8a7da3572a5102aca4060dd1fefff384c59f";
      hash = "sha256-GIRyZ42hY3tiihsAIJvcNCMQJWUp8s2/CTiJxSh8n2M=";
    };
    npmDepsHash = "sha256-LrUoPXIZoZ5bBvinbThgeBkOXhbqIehFHaOvr8ihaek=";
    # The repo ships no test script; default `npm test` would fail.
    dontNpmCheck = true;
    # The bridge's .gitignore lists `dist/`, so the default npm-install-hook
    # (which packs via `npm pack`) drops the TypeScript build output. Copy
    # the build artifacts directly instead.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/node_modules/claude-telegram-bridge
      cp -r dist node_modules package.json package-lock.json $out/lib/node_modules/claude-telegram-bridge/
      runHook postInstall
    '';
  };

  bridgeRoot = "${bridgePkg}/lib/node_modules/claude-telegram-bridge";
  configDir = "${config.xdg.configHome}/claude-telegram-bridge-${cfg.name}";

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
        (claude-telegram-bridge-<name>) and config dir suffix.
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
        ExecStart = "${pkgs.nodejs_22}/bin/node ${bridgeRoot}/dist/index.js";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStartSec = "10min";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
