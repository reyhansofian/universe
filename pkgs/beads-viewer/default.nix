{ lib, buildGoModule, fetchFromGitHub, git, }:

buildGoModule rec {
  pname = "beads-viewer";
  version = "0.10.2";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "beads_viewer";
    rev = "v${version}";
    hash = "sha256-GteCe909fpjjiFzjVKUY9dgfU7ubzue8vDOxn0NEt/A=";
  };

  vendorHash = "sha256-yhwokKjwDe99uuTlRtyoX4FeR1/RZEu7J0PMdAVrows=";

  # The main binary is bv
  subPackages = [ "cmd/bv" ];

  # Tests require git to be available
  nativeCheckInputs = [ git ];

  ldflags = [ "-s" "-w" "-X main.version=${version}" ];

  meta = with lib; {
    description =
      "Terminal-based task management interface for Beads issue tracking system";
    longDescription = ''
      Beads Viewer (bv) is a TUI application that visualizes Beads projects as
      dependency graphs rather than simple lists, enabling graph-theoretic analysis
      for better work prioritization. Built with the Bubble Tea framework.
    '';
    homepage = "https://github.com/Dicklesworthstone/beads_viewer";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "bv";
  };
}
