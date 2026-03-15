{ lib, buildPythonPackage, fetchPypi, flit-core }:

buildPythonPackage rec {
  pname = "libpulse";
  version = "0.7";
  pyproject = true;

  src = fetchPypi {
    pname = "libpulse";
    inherit version;
    hash = "sha256-+Av6MEeExVDXHjfS6MnLBrf7Y5uYmPd4dowMaaug1Ck=";
  };

  build-system = [ flit-core ];

  pythonImportsCheck = [ "libpulse" ];

  meta = with lib; {
    description = "Asyncio interface to PulseAudio/PipeWire libpulse";
    homepage = "https://gitlab.com/xdegaye/libpulse";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
