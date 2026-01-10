{
  lib,
  buildGoModule,
  fetchFromGitHub,
  git,
}:

buildGoModule rec {
  pname = "beads";
  version = "0.46.0";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  vendorHash = lib.fakeHash;

  # The main binary is bd
  subPackages = [ "cmd/bd" ];

  # Tests require git to be available
  nativeCheckInputs = [ git ];

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "A distributed, git-backed graph issue tracker for AI agents";
    homepage = "https://github.com/steveyegge/beads";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "bd";
  };
}
