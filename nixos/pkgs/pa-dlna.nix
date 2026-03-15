{ lib
, buildPythonPackage
, fetchPypi
, flit-core
, makeWrapper
, psutil
, libpulse
, pulseaudio
, ffmpeg
}:

buildPythonPackage rec {
  pname = "pa-dlna";
  version = "1.2";
  pyproject = true;

  src = fetchPypi {
    pname = "pa_dlna";
    inherit version;
    hash = "sha256-gM/DJebmXaV6XGgbcTEEVsBgKwp7rWc2HHkyztef7xI=";
  };

  build-system = [ flit-core ];
  dependencies = [ psutil libpulse ];
  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/pa-dlna \
      --prefix PATH : "${lib.makeBinPath [ pulseaudio ffmpeg ]}"
  '';

  pythonImportsCheck = [ "pa_dlna" ];

  meta = with lib; {
    description = "Forward PulseAudio/PipeWire audio streams to DLNA devices";
    homepage = "https://gitlab.com/xdegaye/pa-dlna";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
