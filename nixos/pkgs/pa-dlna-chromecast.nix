{ lib
, buildPythonPackage
, fetchFromGitHub
, flit-core
, makeWrapper
, psutil
, libpulse
, pychromecast
, pulseaudio
, ffmpeg
}:

buildPythonPackage rec {
  pname = "pa-dlna-chromecast";
  version = "1.2-59a8127";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "nacho692";
    repo = "pa-dlna-chromecast";
    rev = "59a81279bfc7a4ac179284452424a7670831a770";
    hash = "sha256-VCcNrekAjgbsvbax6EoM4bnQzAIgc6NvRU80om7IpbA=";
  };

  build-system = [ flit-core ];
  dependencies = [ psutil libpulse pychromecast ];
  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/pa-dlna \
      --prefix PATH : "${lib.makeBinPath [ pulseaudio ffmpeg ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pulseaudio ]}"
  '';

  pythonImportsCheck = [ "pa_dlna" ];

  meta = with lib; {
    description = "Forward PulseAudio/PipeWire audio streams to DLNA and Chromecast devices";
    homepage = "https://github.com/nacho692/pa-dlna-chromecast";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
