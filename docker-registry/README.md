# Create your own docker registry on kubernetes

## Domain and certificate
- Your domain must to be able to talk with let's encrypt auth method

## Steps
- Use provided script to create k8s secret from env-vars
`REGISTRY_USER=admin REGISTRY_PASS=admin1234 sh create-htpasswd.sh`
- 
kubectl apply -f docker-registry-nfs-pv.yaml
kubectl apply -f docker-registry-nfs-pvc.yaml
kubectl apply -f docker-registry-deployment.yaml
kubectl apply -f docker-registry-service.yaml
kubectl apply -f docker-registry-ingress-route.yaml
kubectl apply -f docker-registry-certificate.yaml
