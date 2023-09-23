#!/usr/bin/env nu

export def restart-k3s [] {
  ./restart_k3s.sh;
  save-k3s-registries;
  systemctl restart k3s;
  copy-kubeconfig;
  install-gateway-crds;
  install-cilium;
  install-openebs;
  install-certmanager;
  kubectl apply -k stockBuddy/k8s/prod/;
  ./annotate-gateways.nu;
  kubectl apply -f pool.yaml;
}

export def copy-kubeconfig [] {
  cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
}

export def save-k3s-registries [] {
  let registriesfile = 'mirrors:
  noxy.ddns.net:5000:
    endpoint:
      - "http://noxy.ddns.net:5000"'
  $registriesfile | save -f /etc/rancher/k3s/registries.yaml
}

export def install-gateway-crds [] {
  let manifests = [
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.8.1/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml"
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.8.1/config/crd/standard/gateway.networking.k8s.io_gateways.yaml"
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.8.1/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml"
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.8.1/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml"
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.8.1/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml"    
  ]
  $manifests | par-each { kubectl apply -f $in } 
}

export def load-kernel-modules [] {
  sudo modprobe ip6table_filter -v
  sudo modprobe iptable_raw -v
  sudo modprobe iptable_nat -v
  sudo modprobe iptable_filter -v
  sudo modprobe iptable_mangle -v
  sudo modprobe ip_set -v
  sudo modprobe ip_set_hash_ip -v
  sudo modprobe xt_socket -v
  sudo modprobe xt_mark -v
  sudo modprobe xt_set -v
}


export def install-cilium [] {
  cilium install --values ./cilium_values.yaml --version 1.15.0-pre.0 --wait
}

export def install-openebs [] {
  let _ = (kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml);  
}

export def install-certmanager [] {
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    (helm install cert-manager 
      --version v1.13.0
      --namespace cert-manager 
      --set installCRDs=true
      --create-namespace
      --set "extraArgs={--feature-gates=ExperimentalGatewayAPISupport=true}"
      jetstack/cert-manager)

    kubectl apply -f caissuer.yaml
}
