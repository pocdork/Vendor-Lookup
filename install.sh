#!/bin/sh

touch ./src/.hook_url
apt-get update
apt-get install curl
apt-get install xmlstarlet
go install -v github.com/tomnomnom/anew@latest