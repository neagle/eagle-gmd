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


