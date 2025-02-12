{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    k9s
    kubectx
    kubernetes-helm
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
  ];
}
