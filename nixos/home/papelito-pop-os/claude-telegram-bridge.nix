{ ... }:

{
  imports = [ ../modules/claude-telegram-bridge.nix ];

  services.claude-telegram-bridge = {
    enable = true;
    name = "skynet";
    botTokenSecret = "skynet_bot_token";
    bridgePinSecret = "skynet_bridge_pin";
    settings = {
      telegram = {
        allowedUserIds = [ 19468268 ];
        rateLimitPerMinute = 10;
      };
      claude = {
        defaultModel = "sonnet";
        defaultEffort = "high";
        maxBudgetUsd = 5.0;
        defaultTools = [ "Bash" "Edit" "Read" "Write" "Glob" "Grep" ];
        processTimeoutMs = 300000;
      };
      voice = {
        enabled = true;
        whisperModel = "base";
        language = "auto";
        whisperCommand = "whisper";
      };
      projects = {
        assistant.path = "~/Projects/assistant";
      };
      defaults = {
        workingDir = "~";
        streamUpdateIntervalMs = 2000;
      };
    };
  };
}
