::Create Azure Resources
az aks create --resource-group dacrook-akschallenge --name dacrook-akschallenge --location eastus --enable-addons monitoring --kubernetes-version "1.13.5" --generate-ssh-keys --enable-vmss --enable-cluster-autoscaler --min-count 1 --max-count 3
az aks get-credentials --resource-group dacrook-akschallenge --name dacrook-akschallenge
az aks enable-addons --resource-group dacrook-akschallenge --name dacrook-akschallenge --addons http_application_routing
az aks enable-addons --resource-group dacrook-akschallenge --name dacrook-akschallenge --addons monitoring

::Configure Kubernetes
kubectl apply -f helm-rbac.yaml
helm init --service-account tiller
kubectl apply -f log_reader.yaml

:: Force TLS & SSL on UI
helm install stable/cert-manager --name cert-manager --set replicaSet.enabled=true,ingressShim.defaultIssuerName=letsencrypt --set ingressShim.defaultIssuerKind=ClusterIssuer --version v0.5.2
kubectl scale statefulset orders-mongo-mongodb-secondary --replicas=3
kubectl apply -f letsencrypt_cluster_issuer.yaml
kubectl apply -f frontend_certificate.yaml

:: Deploy Mongo DB
helm install stable/mongodb --name orders-mongo --set mongodbUsername=orders-user,mongodbPassword=orders-password,mongodbDatabase=akschallenge

:: Deploy capture order web site
kubectl apply -f captureorder-deployment.yaml
kubectl apply -f captureorder_load_balancer.yaml
kubectl apply -f captureorder_ui.yaml
kubectl apply -f frontend_service.yaml
kubectl apply -f frontend_ingress.yaml
kubectl apply -f horizontal_pod_autoscaler.yaml

