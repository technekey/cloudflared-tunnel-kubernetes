# cloudflared-tunnel-kubernetes
A simple `bash`  script to create a deployment of cloudflared tunnel in the Kubernetes cluster.  You can point the tunnel to any cluster IP service within the cluster. 



## Use case:

Think of a case where you have a cluster IP service within in your Kubernetes cluster. You want to expose it publically(via Cloudflare). This script will help you create a deployment of a tunnel inside the cluster letting you expose the clusterIP service via the tunnel. Now, you can leverage the security provided by Cloudflare to set up access rules.  

### Assumptions:
- You understand how Cloudflare tunnels work. (basic understanding)
- You already have tunnel setup and have its token available to use.
- If you do have a token, you can get it using:
    - `cloudflared access login`
    - `cloudflared tunnel token <tunnel-name>`
