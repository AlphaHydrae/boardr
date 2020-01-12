# Notes

# Observe running container

Open SSH tunnels to EMPD and erlang node:

```bash
ssh -L 4369:127.0.0.1:4369 -L 9000:127.0.0.1:9000 ssh://boardr@127.0.0.1:2222
```

Run an IEx session with the same cookie:

```bash
cd load-testing
export ERLANG_COOKIE="$(docker-compose exec app cat /usr/src/app/releases/COOKIE)"
cd ../server
iex --name "foo@127.0.0.1" --cookie "$ERLANG_COOKIE"
```

# Set up vagrant demo

```bash
kubectl apply -f /vagrant/vagrant/k8s/secrets
kubectl apply -f /vagrant/vagrant/k8s/rp
```

Rinse and repeat:

```bash
kubectl apply -f /vagrant/vagrant/k8s/demo
kubectl get pods
kubectl exec -it -c phoenix "$(kubectl get pods -l 'app.kubernetes.io/component=api' -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')" /usr/src/app/bin/boardr_api eval Boardr.Release.migrate
kubectl logs -f "$(kubectl get pods -l 'app.kubernetes.io/component=api' -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')"
kubectl delete -f /vagrant/vagrant/k8s/demo
```