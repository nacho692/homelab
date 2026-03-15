{ lib, stdenv, fetchurl, meson, ninja, pkg-config, makeWrapper
, libupnpp, curl, libmicrohttpd, jsoncpp, libmpdclient
, python3
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    requests
    bottle
    waitress
    mutagen
    py-sonic
    subsonic-connector
  ]);
in
stdenv.mkDerivation rec {
  pname = "upmpdcli";
  version = "1.9.13";

  src = fetchurl {
    url = "https://www.lesbonscomptes.com/upmpdcli/downloads/${pname}-${version}.tar.gz";
    hash = "sha256-CEH0dn5Pw0l++TREQCbngfqaB8VsZvVJPXlxqv/Bv7g=";
  };

  nativeBuildInputs = [ meson ninja pkg-config makeWrapper ];
  buildInputs = [ libupnpp curl libmicrohttpd jsoncpp libmpdclient pythonEnv ];

  postPatch = ''
    substituteInPlace meson.build \
      --replace-fail "install_dir: '/etc'" "install_dir: get_option('sysconfdir')" \
      --replace-fail "meson.add_install_script('tools/installconfig.sh')" ""
  '';

  postInstall = ''
    # upmpdcli launches Python plugins via /usr/bin/env python3.
    # Put pythonEnv first in PATH so plugin scripts use this interpreter and
    # get all required site-packages (requests, py-sonic, subsonic-connector, ...).
    wrapProgram $out/bin/upmpdcli \
      --prefix PATH : "${pythonEnv}/bin" \
      --set PYTHONNOUSERSITE 1
  '';

  meta = with lib; {
    description = "UPnP audio media renderer based on MPD";
    homepage = "https://www.lesbonscomptes.com/upmpdcli/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
