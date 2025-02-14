{
  lib,
  buildPythonPackage,
  click,
  cve,
  fetchFromGitHub,
  jsonschema,
  pytestCheckHook,
  pythonOlder,
  requests,
  setuptools,
  testers,
}:

buildPythonPackage rec {
  pname = "cvelib";
  version = "1.7.0";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "RedHatProductSecurity";
    repo = "cvelib";
    rev = "refs/tags/${version}";
    hash = "sha256-voUBd4JQLk1Ik7JrhFYnY06AucVTj7WwAjDfjOTSENo=";
  };

  postPatch = ''
    # collective.checkdocs is unmaintained for over 10 years
    substituteInPlace pyproject.toml \
      --replace-fail '"collective.checkdocs",' ""
  '';

  build-system = [ setuptools ];

  dependencies = [
    click
    jsonschema
    requests
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "cvelib" ];

  passthru.tests.version = testers.testVersion { package = cve; };

  meta = with lib; {
    description = "Library and a command line interface for the CVE Services API";
    homepage = "https://github.com/RedHatProductSecurity/cvelib";
    changelog = "https://github.com/RedHatProductSecurity/cvelib/blob/${version}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ raboof ];
    mainProgram = "cve";
  };
}
