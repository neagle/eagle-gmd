# Eagle-GMD

Make sure eagle-core is up and running.
The core waits for the dashboard to come up.

> http://localhost:10908

```sh
# from eagle-core
./scripts/setup
```

Now that the core is listening to the `gmdata` namespace,
you can run the setup to bring up gmdata.

Before connecting, go into ./certs and import a p12 ceritificate
for a user into your web browser. They all have password `greymatter`.

> https://localhost:10809/services/gmdata/gmdata/static/ui

```sh
# from eagle-gmd
./scripts/setup
```

After a while, if the scripts had not bombed out, your kubectl should show pod states like this:

```
> kubectl get pods -A
NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE
kube-system   coredns-7448499f4d-glbmg                  1/1     Running     0          4h23m
kube-system   local-path-provisioner-5ff76fc89d-plw4r   1/1     Running     0          4h23m
kube-system   metrics-server-86cbb8457f-wx78p           1/1     Running     0          4h23m
kube-system   helm-install-traefik-crd-wrrv7            0/1     Completed   0          4h23m
kube-system   helm-install-traefik-qxdc9                0/1     Completed   2          4h23m
kube-system   svclb-traefik-qprkk                       2/2     Running     0          4h22m
kube-system   svclb-traefik-8rzw9                       2/2     Running     0          4h22m
kube-system   svclb-traefik-dshqd                       2/2     Running     0          4h22m
greymatter    svclb-edge-h7mjj                          1/1     Running     0          4h22m
greymatter    svclb-edge-sm856                          1/1     Running     0          4h22m
greymatter    svclb-edge-9wpwq                          1/1     Running     0          4h22m
kube-system   traefik-6b84f7cbc-fx92c                   1/1     Running     0          4h22m
gm-operator   greymatter-operator-0                     1/1     Running     0          4h22m
spire         server-0                                  2/2     Running     0          4h22m
spire         agent-npvk5                               1/1     Running     0          4h22m
spire         agent-rqkt7                               1/1     Running     0          4h22m
greymatter    edge-55bbbc8c65-5dsw4                     1/1     Running     0          4h22m
spire         agent-4jjxw                               1/1     Running     0          4h22m
greymatter    dashboard-996685f44-vrnlr                 2/2     Running     0          4h22m
greymatter    catalog-7fdd8c5f5c-g8ngm                  2/2     Running     0          4h22m
greymatter    prometheus-0                              2/2     Running     0          4h22m
greymatter    greymatter-datastore-0                    2/2     Running     0          4h22m
greymatter    controlensemble-0                         3/3     Running     0          4h22m
gmdata        svclb-edge-c67gn                          1/1     Running     0          4h18m
gmdata        svclb-edge-vgxmr                          1/1     Running     0          4h18m
gmdata        edge-56576d8d7d-7fzlz                     1/1     Running     0          4h18m
gmdata        svclb-edge-x7474                          1/1     Running     0          4h18m
gmdata        jwt-security-7b669fc78-zbptd              2/2     Running     0          4h18m
gmdata        hello-world-c8fb44c76-jgcrz               2/2     Running     0          4h18m
gmdata        mongo-0                                   2/2     Running     0          4h17m
gmdata        gmdata-8684f8458d-hlhj6                   2/2     Running     0          4h18m
gmdata        gmdata-8684f8458d-95xq6                   2/2     Running     0          4h17m
gmdata        zk-0                                      2/2     Running     0          4h17m
gmdata        kafka-0                                   2/2     Running     4          4h17m
gmdata        greymatter-sync-0                         1/1     Running     8          4h17m
```

When your cluster is clean, the dashboard and gm-data should be running:

- The Dashboard is at: http://localhost:10908
- The gm-data app is at: https://localhost:10809/services/gmdata/gmdata/static/ui


# The GM-Data Service

## Tutorial On gmdata itself

Now that gm-data is running, you want to put some data into it. See the ./tutorial direcory for these basic things:

```
tutorial/
├── listingExample.sh
├── README.md
└── uploadsExample.py
``` 

If you cd into the tutorial directory, you can run a script to populate gm-data automatically from things in your ~/Downloads directory.
The listingExample is also a minimal example of using the gmdata API in Python to write files into gmdata.
And then you can go into the UI to see that these files exist.
Then after that, look in `listingExample.sh` for examples of programmatically reading back out of gmdata.
Both of these use PKI certificates, because you must be identified as an actual user to do anything in gm-data, as it is
a permissioned filesystem.

## Configuration Concerns

- If you want to use S3 for buckets with gm-data, set `USES3=true`, the `AWS_S3_BUCKET`, and AWS creds in `k8s/gmdata/gmdata.yaml`.
  For real deployments, you want this so that storage is limitless with respect to file size. You can simply ignore
  (or remove) the `/buckets` volume mount if you are using S3.
- Take note of volume mount sizes before bringing everything up, so that you don't run out of space.

When the service is up and running, and you can see it in the browser, run a test to upload files in your ~/Downloads dir:

> read ./tutorial/README.md to get started on using gmdata API

```
cd tutorial
./uploadsExample.py
``` 

## TLDR

Shortcut to launch it and have it being tested before you come back

```
(cd ../eagle-core && ./scripts/setup) && (cd ../eagle-gmd && ./scripts/setup && sleep 420 && cd tutorial && ./uploadsExample.py)
```

## TODO

- Spire, especially against JWT service doesn't seem right, in spite of everything functioning
- The tutorial load test seems somewhat slow. We should eventually get at least a few hundred files fully uploaded and indexed per minute.