{ pkgs, lib, ... }:
{
  home.username = lib.mkDefault "papelito";
  home.homeDirectory = lib.mkDefault "/home/papelito";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nixd
    nixpkgs-fmt
    godot
    telegram-desktop
    nix-direnv
    magic-wormhole
    offpunk
    claude-code
    hermes-agent
    eternal-terminal
    codex
    ed
    ripgrep
    uv
  ];

  programs.bash.enable = true;
  programs.bash.profileExtra = ''
    if [[ -n "''${CODEX_EXECUTABLE_PATH:-}" ]] && command -v direnv >/dev/null 2>&1; then
      unset DIRENV_DIR DIRENV_FILE DIRENV_DIFF DIRENV_WATCHES
      eval "$(direnv export bash 2>/dev/null || true)"
    fi
  '';
  programs.starship.enable = true;
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };
}
