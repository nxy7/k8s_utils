#!/usr/bin/env nu

export def main [svcName = "cilium-gateway-gateway": string, --namespace (-n) = "default": string, --ip = "194.163.166.184": string, --ipPool = "194.163.166.183/28": string] {
  annotate $svcName $namespace $ip $ipPool
}

export def annotate [serviceName: string, namespace: string, ip: string, ipPool: string] {
  try {
    createPoolString $ipPool | kubectl delete -f -
  }
  try {kubectl annotate svc $serviceName -n $namespace $'io.cilium/lb-ipam-ips=($ip)'}
  createPoolString $ipPool | kubectl apply -f -
}

export def createPoolString [ipPool = "194.163.166.183/28": string] {
  return $'apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "blue-pool"
spec:
  cidrs:
  - cidr: "($ipPool)"'
}

