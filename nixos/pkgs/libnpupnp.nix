{ lib, stdenv, fetchurl, meson, ninja, pkg-config, curl, expat, libmicrohttpd }:

stdenv.mkDerivation rec {
  pname = "libnpupnp";
  version = "6.2.3";

  src = fetchurl {
    url = "https://www.lesbonscomptes.com/upmpdcli/downloads/${pname}-${version}.tar.gz";
    hash = "sha256-Vj0qnkr+YDcXND3EZnwLicagFwCKxrUiYtoXoeT2u5Y=";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ curl expat libmicrohttpd ];

  meta = with lib; {
    description = "UPnP library based on npupnp";
    homepage = "https://www.lesbonscomptes.com/upmpdcli/";
    license = licenses.bsd2;
    platforms = platforms.linux;
  };
}
