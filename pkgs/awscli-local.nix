{ lib, python3, fetchPypi }:

let
  localstack-client = python3.pkgs.buildPythonPackage rec {
    pname = "localstack-client";
    version = "2.12";
    format = "setuptools";

    src = fetchPypi {
      pname = "localstack_client";
      inherit version;
      hash = "sha256-27mHEv0siGnV3+16LKAGuVx3UP6aQ68SPvBU78fn67Q=";
    };

    propagatedBuildInputs = [ python3.pkgs.boto3 ];

    doCheck = false;

    meta = with lib; {
      description = "Lightweight Python client for LocalStack";
      homepage = "https://github.com/localstack/localstack-python-client";
      license = licenses.asl20;
    };
  };
in
python3.pkgs.buildPythonApplication rec {
  pname = "awscli-local";
  version = "0.22.2";
  format = "setuptools";

  src = fetchPypi {
    pname = "awscli_local";
    inherit version;
    hash = "sha256-B8Uyw3J1O/XxVCZFHckdbuyd6HeXSASTKamogr2sigs=";
  };

  propagatedBuildInputs = [ localstack-client ];

  doCheck = false;

  meta = with lib; {
    description = "Thin wrapper around the aws CLI for use with LocalStack";
    homepage = "https://github.com/localstack/awscli-local";
    license = licenses.asl20;
    mainProgram = "awslocal";
  };
}
