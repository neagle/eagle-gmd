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

# The GM-Data Service

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
