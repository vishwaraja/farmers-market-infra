# =============================================================================
# KONG MODULE OUTPUTS
# =============================================================================

output "kong_namespace" {
  description = "Kong namespace name"
  value       = kubernetes_namespace.kong.metadata[0].name
}

output "kong_proxy_service_name" {
  description = "Kong proxy service name"
  value       = kubernetes_service.kong_proxy.metadata[0].name
}

output "kong_admin_service_name" {
  description = "Kong admin service name"
  value       = kubernetes_service.kong_admin.metadata[0].name
}

output "kong_proxy_service_port" {
  description = "Kong proxy service port"
  value       = kubernetes_service.kong_proxy.spec[0].port[0].port
}

output "kong_admin_service_port" {
  description = "Kong admin service port"
  value       = kubernetes_service.kong_admin.spec[0].port[0].port
}

output "kong_ingress_name" {
  description = "Kong ingress name"
  value       = kubernetes_ingress_v1.kong_ingress.metadata[0].name
}

output "kong_database_service_name" {
  description = "Kong database service name"
  value       = kubernetes_service.kong_database.metadata[0].name
}

output "kong_admin_url" {
  description = "Kong Admin API URL (internal)"
  value       = "http://${kubernetes_service.kong_admin.metadata[0].name}.${kubernetes_namespace.kong.metadata[0].name}.svc.cluster.local:${kubernetes_service.kong_admin.spec[0].port[0].port}"
}

output "kong_proxy_url" {
  description = "Kong Proxy URL (external LoadBalancer)"
  value       = "http://${kubernetes_service.kong_proxy.status[0].load_balancer[0].ingress[0].hostname}"
}

output "kong_proxy_internal_url" {
  description = "Kong Proxy URL (internal)"
  value       = "http://${kubernetes_service.kong_proxy.metadata[0].name}.${kubernetes_namespace.kong.metadata[0].name}.svc.cluster.local:${kubernetes_service.kong_proxy.spec[0].port[0].port}"
}

output "kong_deployment_info" {
  description = "Kong deployment information"
  value = {
    namespace = kubernetes_namespace.kong.metadata[0].name
    proxy_service = kubernetes_service.kong_proxy.metadata[0].name
    admin_service = kubernetes_service.kong_admin.metadata[0].name
    database_service = kubernetes_service.kong_database.metadata[0].name
    ingress_name = kubernetes_ingress_v1.kong_ingress.metadata[0].name
  }
}

output "kong_connection_commands" {
  description = "Commands to connect to Kong services"
  value = {
    port_forward_admin = "kubectl port-forward -n ${kubernetes_namespace.kong.metadata[0].name} svc/${kubernetes_service.kong_admin.metadata[0].name} 8001:8001"
    port_forward_proxy = "kubectl port-forward -n ${kubernetes_namespace.kong.metadata[0].name} svc/${kubernetes_service.kong_proxy.metadata[0].name} 8000:8000"
    check_status = "kubectl get pods -n ${kubernetes_namespace.kong.metadata[0].name}"
    check_services = "kubectl get services -n ${kubernetes_namespace.kong.metadata[0].name}"
  }
}
