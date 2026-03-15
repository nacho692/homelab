{ lib, stdenv, fetchurl, meson, ninja, pkg-config, libnpupnp, curl, expat }:

stdenv.mkDerivation rec {
  pname = "libupnpp";
  version = "1.0.3";

  src = fetchurl {
    url = "https://www.lesbonscomptes.com/upmpdcli/downloads/${pname}-${version}.tar.gz";
    hash = "sha256-07IBYZqEg3J53Ebut8yqp5YNQ3LbEbQ88rFDtdm9Mi4=";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ libnpupnp curl expat ];


  meta = with lib; {
    description = "C++ wrapper library over libnpupnp";
    homepage = "https://www.lesbonscomptes.com/upmpdcli/";
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
  };
}
