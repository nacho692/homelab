{ pkgs, ... }:

let
  pname = "cursor";
  version = "2.3.34";
  name = "${pname}-${version}";

  src = pkgs.fetchurl {
    url = "https://downloads.cursor.com/production/643ba67cd252e2888e296dd0cf34a0c5d7625b96/linux/x64/Cursor-${version}-x86_64.AppImage";
    sha256 = "sha256-Zsu8COFf0GHzRUBgQX6yoWBbNXbjXP8VQsPa5Nd3w+o=";
  };

  appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };
in
  pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    pkgs = pkgs;
    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname} --ozone-platform=wayland'
      cp -r ${appimageContents}/usr/share/icons $out/share

      mv $out/bin/${pname} $out/bin/.${pname}-unwrapped
      echo '#!/bin/sh' > $out/bin/${pname}
      echo "exec $out/bin/.${pname}-unwrapped --ozone-platform=wayland \"\$@\"" >> $out/bin/${pname}
      chmod +x $out/bin/${pname}
    '';

    extraBwrapArgs = [
      "--bind-try /etc/nixos/ /etc/nixos/"
    ];

    dieWithParent = false;

    extraPkgs = pkgs: with pkgs; [
      unzip
      autoPatchelfHook
      asar
      (buildPackages.wrapGAppsHook3.override {inherit (buildPackages) makeWrapper;})
    ];
}
