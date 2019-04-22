resource "kubernetes_persistent_volume_claim" "nexus_pvc" {
  metadata {
    name      = "nexus-pvc"
    namespace = "tools"
    labels {
      app = "nexus-deployment"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests {
        storage = "10Gi"
      }
    }
    storage_class_name = "standard"
  }
}
resource "kubernetes_deployment" "nexus_deployment" {
  metadata {
    name      = "nexus-deployment"
    namespace = "tools"
    labels {
      app = "nexus-deployment"
    }
  }
  spec {
    replicas = 1
    template {
      metadata {
        labels {
          app = "nexus-deployment"
        }
      }
      spec {
        volume {
          name = "nexus-volume"
          persistent_volume_claim {
            claim_name = "nexus-pvc"
          }
        }
        container {
          name  = "nexus-container"
          image = "fsadykov/docker-nexus"
          port {
            name           = "nexus-http"
            container_port = 8081
          }
          port {
            name           = "docker-repo"
            container_port = 8085
          }
          env {
            name  = "INSTALL4J_ADD_VM_PARAMS"
            value = "-Xms1200M -Xmx1200M -XX:MaxDirectMemorySize=2G -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
          }
          resources {
            requests {
              memory = "4800Mi"
              cpu    = "500m"
            }
          }
          volume_mount {
            name       = "nexus-volume"
            mount_path = "/nexus-data"
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "nexus_service" {
  metadata {
    name      = "nexus-service"
    namespace = "tools"
  }
  spec {
    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = "8081"
    }
    port {
      name        = "docker-repo"
      protocol    = "TCP"
      port        = 8085
      target_port = "8085"
    }
    selector {
      app = "nexus-deployment"
    }
    type = "LoadBalancer"
  }
}