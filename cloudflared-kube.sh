#!/bin/bash

#defaults
namespace="cloudflared"
secret_name="cloudflared-secret-token"

echo "########################################################################"
echo "# This script will set up a cloudflared tunnel deployment (1 replica)in #"
echo "# the Kubernetes cluster.                                              #"
echo "########################################################################"

read -p "Please enter the name of tunnel:"  tunnel_name
if [ ! -z "$tunnel_name" ];then
    auto_token=$(cloudflared tunnel token  $tunnel_name 2>&1)
fi
read -p "Please enter the token value:[${auto_token:-''}]"  input_token
read -p "Please enter the namespace to set up the cloudflared tunnel [$namespace]: " input_namespace
read -p "Please enter the name of the secret to store the token [$secret_name]: " input_secret_name

token="${input_token}"
namespace="${input_namespace:-$namespace}"
secret_name="${input_secret_name:-$secret_name}"

if [ -z "$token" ]; then
    echo "Error: Token value is empty."
    exit 1
fi

if [ -z "$namespace" ]; then
    echo "Error: Namespace value is empty."
    exit 1
fi

if [ -z "$secret_name" ]; then
    echo "Error: Secret name value is empty."
    exit 1
fi


echo "+--------------------------------------------------------------+"
echo "Namespace: $namespace"
echo "Secret name: $secret_name"
echo "Token: $token"
echo "+--------------------------------------------------------------+"

if kubectl get ns | grep -qw "$namespace"; then
    echo "Info: The $namespace namespace is already present"
else
    echo "Info: Creating $namespace namespace"
    kubectl create ns "$namespace"
fi

echo "
---
apiVersion: v1
kind: Secret
metadata:
  name: $secret_name
  namespace: $namespace
type: Opaque
data:
  token: $(echo -n $token | base64 -w 0)" |kubectl create -f -

echo "
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: cloudflared
  name: cloudflared
  namespace: $namespace
spec:
  selector:
    matchLabels:
      app: cloudflared
  template:
    metadata:
      labels:
        app: cloudflared
    spec:
      containers:
      - name: cloudflared
        image: cloudflare/cloudflared
        imagePullPolicy: Always
        env:
        - name: TUNNEL_TOKEN
          valueFrom:
            secretKeyRef:
              name: $secret_name
              key: token
        args:
        - "tunnel"
        - "--no-autoupdate"
        - "run"
        - "--token"
        - "\"\$\(TUNNEL_TOKEN\)\""
      restartPolicy: Always
      terminationGracePeriodSeconds: 60"  |kubectl create -f -

kubectl get -n $namespace deployment
kubectl get -n $namespace secret

echo "==========================================================="
echo "If you wish to delete the resources created by this script:"
echo "run the following commands:"
echo "==========================================================="
echo "kubectl delete -n $namespace deployment cloudflared"
echo "kubectl delete -n $namespace secret $secret_name"
