# 1 ) Makefile aanpassen

PLATFORM=poc
TENANT=<tenant>
DOCKER_REPO_URL=registry.cp.kpn-dsh.com/$(TENANT)
VERSION:=1
tagname=example-python
tenantuserid=<uid>

# 2 ) Uitvoeren
make all

# 3 ) Voorbeeld config @ DSH

{
	"name": "example-python",
	"image": "registry.cp.kpn-dsh.com/<tenant>/example-python:1",
	"cpus": 0.1,
	"mem": 256,
	"env": {
		"stream": "<stream.topic>"
	},
	"instances": 1,
	"singleInstance": false,
	"needsToken": true,
	"user": "<uid>:<uid>"
}