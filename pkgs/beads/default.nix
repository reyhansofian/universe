{ lib, buildGoModule, fetchFromGitHub, git, }:

buildGoModule rec {
  pname = "beads";
  version = "0.46.0";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "v${version}";
    hash = "sha256-PMzLKb0pYKiXdiEXBFe6N4FZ3AaNfvBRZlQBKijtldc=";
  };

  vendorHash = "sha256-BpACCjVk0V5oQ5YyZRv9wC/RfHw4iikc2yrejZzD1YU=";

  # The main binary is bd
  subPackages = [ "cmd/bd" ];

  # Tests require git to be available
  nativeCheckInputs = [ git ];

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "A distributed, git-backed graph issue tracker for AI agents";
    homepage = "https://github.com/steveyegge/beads";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "bd";
  };
}
