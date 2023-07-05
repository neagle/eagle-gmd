#!/bin/env python3

import requests
import os
import json
import random
import sys
from requests_toolbelt.multipart.encoder import MultipartEncoder
import asyncio

## required:
# pip install requests_toolbelt

# usage:
#   ./beater.py ~/Downloads
#

downloadsdir = os.path.expanduser("~/Downloads")
proxy = "https://localhost:10809"
gmdataUrl = proxy + "/services/gmdata/gmdata"
rootDir = "/world"
userSubdirs = {}

def get_script_path():
    return os.path.dirname(os.path.realpath(sys.argv[0]))+"/"

def setup():
  global usersJson
  f = open(get_script_path()+"../certs/users.json")
  usersJson = json.load(f)
  f.close()


def maybePushDir(userdn):
    r = random.randint(0,10)
    if r == 0:
        stack = dirsOf(userdn)
        stack.append("dir%d" % random.randint(0,20))
        userSubdirs[userdn] = stack

def maybePopDir(userdn):
    r = random.randint(0,10)
    if r == 0:
       d = dirsOf(userdn)
       if len(d) > 0:
           l = len(userSubdirs[userdn])
           userSubdirs[userdn] = userSubdirs[userdn][0:l-1]

def dirsOf(userdn):
    if userdn in userSubdirs:
        return userSubdirs[userdn]
    else:
        return []

def identityFromDN(dn):
  tokens = dn.split(",")
  return tokens[0][3:]

def upload(files):
  # random user
  uinfo = random.choice(list(usersJson["users"]))
  userdn = uinfo["label"]
  homeDirName = uinfo["values"]["email"][0]
  identity = identityFromDN(userdn)
  identityPassword = "greymatter" # all user p12 files in this test have hardcoded passwords
  fName = random.choice(files)
  maybePushDir(userdn)
  maybePopDir(userdn)
  thePath = pathOf(userdn)
  c = doUpload(fName, thePath, homeDirName, userdn, identity, identityPassword)
  asyncio.run(c)
  
# You can set an openpolicyagent permission on an object, like this
# this makes it ReadOnly access for the user with this email
def policyAllCanReadEmailOwns(email):
    return """package policy
    default R = true
    default X = true
    default C = false
    default U = false
    default D = false
    default P = false
    canEdit{ input.claims.values.email[_] == "%s" }
    C{canEdit}
    U{canEdit}
    D{canEdit}
    P{canEdit}
    """ % (email)

def pathOf(userdn):
    d = dirsOf(userdn)
    if len(d) == 0:
        return ""
    return "/%s" % "/".join(d)

#
# This is how you perform an upload into gmdata:
# - use an mTLS client, which means using the user's pem cert,key, and the CA trust
# - make a metadata object in multipart-mime to describe the upload
# - supply the blob after the metadata object
#
async def doUpload(fName, thePath, email, userdn, identity, identityPassword):
    global rootDir
    global downloadsdir
    global gmdataUrl
    into = ("%s/%s%s" % (rootDir, email, thePath))
    print("uploading for %s: %s/%s" % (userdn,into,fName))
    # You need enough metadata to say that you want an upsert of a file, into a directory. It needs a name, and can take a default permission
    metadata = [{
      "action": "U",
      "parentoid": into,
      "name": fName,
      "isfile": True,
      "objectpolicy": {
        "rego": policyAllCanReadEmailOwns(email) 
      },
      "security": {
        "label": "PUBLIC-READ",
        "background": "green",
        "foreground": "white"
      }
    }]
    # The upload is multipart mime. If a file is being upserted, then a blob for each object needs to be included.
    with open(downloadsdir+"/"+fName,"rb") as fh:
      md = MultipartEncoder([
        ('json', ("metadata", json.dumps(metadata), "application/json")),
        ('file', ("blob",     fh,                   "application/octet-stream")),
      ])
      result = requests.post(
        gmdataUrl + "/write",
        data = md,
        headers = {
          "user_dn": userdn,
          "content-type": md.content_type,
        },
        # this is an mTLS connection to the server... we trust the CA
        verify=get_script_path()+"../certs/gmdata_ca_cert.pem",
        # and we upload as our own user, using pem format
        cert=(
                get_script_path()+"../certs/gmdata_%s_cert.pem" % identity,
                get_script_path()+"../certs/gmdata_%s_key.pem" % identity
              ),
      )
      if result.status_code != 200:
        print("FAIL to write %s/%s by %s" % (into,fName,userdn))

# This just looks in the directory you chose for suitable file types
def randomFiles(d):  
  files = []
  for f in os.listdir(d):
    if f.endswith(".txt"):
      files.append(f)
    if f.endswith(".pdf"):
      files.append(f)
    if f.endswith(".doc"):
      files.append(f)
    if f.endswith(".docx"):
      files.append(f)
    if f.endswith(".xls"):
      files.append(f)
    if f.endswith(".xlsx"):
      files.append(f)
    if f.endswith(".png"):
      files.append(f)
    if f.endswith(".mp4"):
      files.append(f)
    if f.endswith(".jpg"):
      files.append(f)
  return files

def uploadLoop():
  while True:
    f = randomFiles(downloadsdir)
    upload(f)

def start():
  setup()
  uploadLoop()

start()
