HOST ?= localhost
NAMESPACE ?= nameko
CONTEXT ?= kind-$(NAMESPACE)
LOCAL_DNS ?= 127.0.0.1.nip.io #address for epinio
SERVICE_DEPENDENCIES := gateway orders products 
IMAGES := gateway orders products 
TAG ?= dev


# all in one
kind-create-cluster:
	kind create cluster --config kind-config.yaml --name $(NAMESPACE)
	kind export kubeconfig --name $(NAMESPACE)
	NEWURL=$$(kubectl config view | grep -B1 'name: $(CONTEXT)' | grep server: | awk '{print $$2}' | sed -e 's/0.0.0.0/$(HOST)/') ; \
		kubectl config set-cluster $(CONTEXT) --server=$${NEWURL} --insecure-skip-tls-verify=true 

# src: https://kind.sigs.k8s.io/docs/user/ingress/
kind-setup-ingress:
	kubectl apply -f nginx_components.yaml 
	sleep 30
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=250s

undeployK8:
	# $(MAKE) delete-namespace
	kind delete cluster --name $(NAMESPACE)

deployK8: kind-create-cluster kind-setup-ingress
	# $(MAKE) init-helm
	$(MAKE) create-namespace
	$(MAKE) deploy-dependencies
	$(MAKE) install-charts

# epinio
deploy-epinio: kind-create-cluster kind-setup-ingress kind-setup-cert-manager
	helm repo add epinio https://epinio.github.io/helm-charts
	helm install epinio -n epinio --create-namespace epinio/epinio --set global.domain=$(LOCAL_DNS)
	epinio login -u admin https://epinio.$(LOCAL_DNS)
	$(MAKE) push-epinio-nameko-images

kind-setup-cert-manager:
	kubectl apply -f cert-manager.yaml
	sleep 20
	kubectl wait --namespace cert-manager \
    --for=condition=available deployment/cert-manager \
    --timeout=300s

create-epinio-service-dependencies:
	for service_name in $(SERVICE_DEPENDENCIES); do epinio service create $$service_name-dev $(NAMESPACE)-$$service_name; done
	$(MAKE) bind-epinio-services

push-epinio-nameko-images: load-nameko-docker-images generate-helm-tgz
	for image in $(IMAGES); do epinio push -n $$image --container-image-url $(NAMESPACE)/nameko-example-$$image:$(TAG) --timeout-multiplier 1000 --app-chart custom-app; done
	$(MAKE) create-epinio-service-dependencies

generate-helm-tgz: 
	cd charts/epinio-custom-resource && \
	helm package . && \
	tgz_url=$$(curl --upload-file ./epinio-application-0.1.26.tgz https://transfer.sh/epinio-application-0.1.26.tgz); \
	rm -f epinio-application-0.1.26.tgz && \
	cd ../..; \
	$(MAKE) install-epinio-custom-chart IMAGE_NAME=epinio-application-0.1.26.tgz CHART_URL=$$tgz_url; 

install-epinio-custom-chart: 
	cp charts/epinio-app-chart.yaml charts/epinio-app-chart-adapted.yaml
#echo "  helmChart: $(CHART_URL)" >> charts/epinio-app-chart-adapted.yaml
	kubectl apply -f charts/epinio-app-chart-adapted.yaml
	rm charts/epinio-app-chart-adapted.yaml
	
load-nameko-docker-images:
	cd ..; $(MAKE) build
	kind load docker-image $(NAMESPACE)/nameko-example-gateway:$(TAG) --name $(NAMESPACE)
	kind load docker-image $(NAMESPACE)/nameko-example-orders:$(TAG) --name $(NAMESPACE)
	kind load docker-image $(NAMESPACE)/nameko-example-products:$(TAG) --name $(NAMESPACE)

bind-epinio-services:
	for image in $(IMAGES); do \
		for service in $(SERVICE_DEPENDENCIES); do \
			epinio service bind nameko-$$service $$image; \
		done; \
	done
	$(MAKE) epinio-set-app-variables

epinio-set-app-variables:
	$(MAKE) epinio-bind-rabbitmq-vars
	$(MAKE) epinio-bind-redis-vars
	$(MAKE) epinio-bind-postgres-vars

epinio-bind-rabbitmq-vars:
	for app in $(IMAGES); do \
		epinio app env set $$app RABBIT_PASSWORD \
			$$(kubectl get secret $$(kubectl get secrets -n workspace -o jsonpath='{range .items[?(@.data.rabbitmq-password)]}{.metadata.name}{"\n"}{end}' | grep rabbitmq) -n workspace -o jsonpath='{.data.rabbitmq-password}' | base64 --decode); \
		epinio app env set $$app RABBIT_HOST $$(kubectl get svc -n workspace | grep rabbit | grep -v headless | awk '{print $$1}').workspace.svc.cluster.local; \
		epinio app env set $$app RABBIT_PORT 5672; \
		epinio app env set $$app RABBIT_USER user; \
		epinio app env set $$app RABBIT_MANAGEMENT_PORT 15672; \
	done

epinio-bind-redis-vars:
	epinio app env set products REDIS_PASSWORD \
		$$(kubectl get secret $$(kubectl get secrets -n workspace -o jsonpath='{range .items[?(@.data.redis-password)]}{.metadata.name}{"\n"}{end}' | grep redis) -n workspace -o jsonpath='{.data.redis-password}' | base64 --decode); \
	epinio app env set products REDIS_HOST \
		$$(kubectl get svc -n workspace | grep redis-master | awk '{print $$1}').workspace.svc.cluster.local; \
	epinio app env set products REDIS_PORT 6379
	epinio app env set products REDIS_INDEX 11

epinio-bind-postgres-vars:
	epinio app env set orders DB_HOST \
		$$(kubectl get svc -n workspace | grep postgres | grep -v postgresql-hl | awk '{print $$1}').workspace.svc.cluster.local; \
	epinio app env set orders DB_PASSWORD $() \
		$$(kubectl get secret $$(kubectl get secrets -n workspace -o jsonpath='{range .items[?(@.data.postgres-password)]}{.metadata.name}{"\n"}{end}' | grep postgres) -n workspace -o jsonpath='{.data.postgres-password}' | base64 --decode); \
	epinio app env set orders DB_USER postgres
	epinio app env set orders DB_NAME postgres

# test epinio
epinio-smoke-test:
	../test/nex-smoketest.sh https://gateway.$(LOCAL_DNS)

# test
smoke-test:
	../test/nex-smoketest.sh http://localhost

perf-test:
	cd ..; ./test/nex-bzt.sh http://localhost

# helm
init-helm:
	helm repo add stable https://charts.helm.sh/stable
	helm repo update

list-charts:
	helm --kube-context=$(CONTEXT) list --namespace=$(NAMESPACE)

deploy-dependencies:
	helm upgrade broker stable/rabbitmq --install \
		--namespace $(NAMESPACE) --kube-context=$(CONTEXT)
	helm upgrade db stable/postgresql --install \
		--set postgresqlDatabase=orders \
		--namespace $(NAMESPACE) --kube-context=$(CONTEXT)
	helm upgrade cache stable/redis --install \
		--namespace $(NAMESPACE) --kube-context=$(CONTEXT)
	kubectl --context=$(CONTEXT) --namespace=$(NAMESPACE) get pods

install-charts:
	cd ..; $(MAKE) build
	kind load docker-image $(NAMESPACE)/nameko-example-gateway:$(TAG) --name $(NAMESPACE)
	kind load docker-image $(NAMESPACE)/nameko-example-orders:$(TAG) --name $(NAMESPACE)
	kind load docker-image $(NAMESPACE)/nameko-example-products:$(TAG) --name $(NAMESPACE)
	$(MAKE) SERVICE_NAME=gateway install-chart
	$(MAKE) SERVICE_NAME=orders install-chart
	$(MAKE) SERVICE_NAME=products install-chart

test-charts:
	$(MAKE) SERVICE_NAME=gateway test-chart
	$(MAKE) SERVICE_NAME=orders test-chart
	$(MAKE) SERVICE_NAME=products test-chart

lint-charts:
	$(MAKE) SERVICE_NAME=gateway lint-chart
	$(MAKE) SERVICE_NAME=orders lint-chart
	$(MAKE) SERVICE_NAME=products lint-chart

test-chart:
	helm upgrade $(SERVICE_NAME) charts/$(SERVICE_NAME) --install \
	--namespace=$(NAMESPACE) --kube-context $(CONTEXT) \
	--dry-run --debug --set image.tag=$(TAG)

install-chart:
	helm upgrade $(SERVICE_NAME) charts/$(SERVICE_NAME) --install \
	--namespace=$(NAMESPACE) --kube-context=$(CONTEXT) \
	--set image.tag=$(TAG)

lint-chart:
	helm lint charts/$(SERVICE_NAME) --strict
