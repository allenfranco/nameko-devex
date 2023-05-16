
INSTALLATION

STEP 01 - setup your environment:
 k8s
 epinieo
 kind
 docker
 helm
 python3
 conda

STEP 02 - execute `../k8s/` folder 

	$ make deployK8 - to deploy
	$ make undeployk8 - to undeploy

	to run epineo
	$ make deploy epineo


PATCHES

FIX 01
 - Debian repository issues with default docker image, so i changed to python:3.7.13-slim-buster

FIX 02
 - Change version for alembic==9.3 to alembic==9.3

FIX 03
 - libpq.so.5: cannot open shared object file: No such file or directory

FIX 04
 - fiz error:
 error: no matching resources found
make: *** [kind-setup-ingress] Error 1

FIX 05
 - bring ingress locally

FIX 06 
 - Helm broker template for rabbitmq is deprecated, for this test i'll continue to use.


GOODS

STEP 01 - Created DNS to access via browser as https://localhost.nip.io

STEP 02 - Created deploy for Epinio in our kind cluster and login as admin in eplinio

STEP 03 - Created deploy for cert-manager in our kind cluster

STEP 04 - Create the services dependencies to install the apps


KNOW ISSUES

ISSUE 01 - Deprecated helm syntax need to be updated

ISSUE 02 - products are not listed in epinio

ISSUE 03 - bind for the applications are not stable

ISSUE 04 - used ports when cluster is restarted need to be addressed


THANKS FOR THIS AMAZING CHANCE, I ENJOYED TO KNOW THIS !!!