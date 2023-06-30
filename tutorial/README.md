Tutorial
=====

In order to verify that things work, you can either bring up the UI to look at files, and manually upload them, or run this python script to upload things as they exist in your ~/Downloads directory.
This python script also serves as an example of HOW to perform such writes programmatically.

## uploadExample.py

This code sits in a loop and:

- pick a random user from the certs dir
- pick a random file out of your download dir (ie: load up with files that you want to test in your mesh)
- sets a simple Open Policy Agent policy on the upload
- run the upload as a random user, via setting the `USER_VALUE` value

Run this for a little bit to poulate gmdata with data

```
./uploadExample.py
```

Go look at it in the browser at:

https://localhost:10809/services/gmdata/gmdata/static/ui/index.html

You should see that for each user, in `/world` there is a home dir named after that user's first `email` in their JWT token.
This is exactly like home directories in Linux, except having a signed email address _gives access_ to creating that home
directory in `/world`, the root where our users live.

> Note that you need to import a `../certs/gmdata_${user}.p12` with password `greymatter` to visit that url in the browser as a user.

Once you have some data actually in gmdata, run some examples of simple shell script code reading gm-data:

```
./listingExample.sh
```
