{ lib, buildPythonPackage, fetchPypi, poetry-core, py-sonic }:

buildPythonPackage rec {
  pname = "subsonic-connector";
  version = "0.3.10";
  pyproject = true;

  src = fetchPypi {
    pname = "subsonic_connector";
    inherit version;
    hash = "sha256-sxblYtn1/Dfsa9cwloxedC9S199pmttFqYfGgiJ80ys=";
  };

  build-system = [ poetry-core ];
  dependencies = [ py-sonic ];

  meta = with lib; {
    description = "SubSonic Connector based on py-sonic";
    homepage = "https://github.com/GioF71/subsonic-connector";
    license = licenses.mit;
  };
}
