# main.tf
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "null_resource" "start_minikube" {

  provisioner "local-exec" {
    command = "minikube start --driver qemu --network socket_vmnet"
  }
}

resource "helm_release" "echo" {
  name       = "echo-webapp"

  chart      = "./echo-webapp"
  version    = "0.2.0"

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "replicaCount"
    value = "3"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "7.3.7"
  namespace  = "monitoring"
  values = [
    <<EOF
service:
  type: NodePort
datasources:
 datasources.yaml:
   apiVersion: 1
   datasources:
   - name: Prometheus
     type: prometheus
     url: http://prometheus-server
adminUser: admin
adminPassword: strongpassword
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default

dashboards:
  default:
    echo:
      json: |
        ${indent(8, file("${path.module}/devops/grafana/dashboards/echo.json"))}
EOF
  ]
}
