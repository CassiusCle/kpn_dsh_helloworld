```bash
make all
```
OR

```bash docker login registry.cp.kpn-dsh.com
docker build -t consumer -f Dockerfile --build-arg tenantuserid=2065 .
docker tag  consumer registry.cp.kpn-dsh.com/troef-tue/consumer:1
docker push registry.cp.kpn-dsh.com/troef-tue/consumer:1
```