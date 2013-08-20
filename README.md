#MongoDB with SSL
---

## What and Why
MongoDB is __great__, however for some particular reason it doesn't include SSL support in the publicly available binaries and distributions.

We require such support for a couple of projects so I decided to give it a try and create a builder script that was as __reusable__ and __automatic__ as possible.

## Disclaimer
This was my very first approach to the hole DEB package system, I'm sure is far from perfect and any enhancements/contributions are deeply appreciated ;)

## Usage
Enough introduction, how to actually use the thing and what it will do!

Just go ahead and run the go.sh script, I run it on a completely new xlarge __Ubuntu 12.04.2 64 bit__ instance on AWS, it will ask for some input along the way and you'll end with a package like such on the base dir:

__mongodb-ssl_VERSION_amd64.deb__

```
# To run the builder
./go.sh
```

```
# To install the package run something like:
sudo dpkg -i mongodb-ssl_2.4.5_amd64.deb
```

```
# Inspect what was actually installed
dpkg -L mongodb-ssl
```

```
# Remove for good
dpkg --purge mongodb-ssl
```