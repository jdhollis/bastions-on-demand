(ns bastion.env)

(def cluster-name (System/getenv "CLUSTER_NAME"))
(def cluster-subnet-ids (System/getenv "CLUSTER_SUBNET_IDS"))
(def cluster-vpc-default-security-group-id (System/getenv "CLUSTER_VPC_DEFAULT_SECURITY_GROUP_ID"))
(def cluster-vpc-id (System/getenv "CLUSTER_VPC_ID"))
(def container-name (System/getenv "CONTAINER_NAME"))
(def service-name (System/getenv "SERVICE_NAME"))
(def task-family (System/getenv "TASK_FAMILY"))
