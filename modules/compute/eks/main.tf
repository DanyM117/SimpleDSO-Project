module "eks_aws" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 20.0"

    name = var.eks_name
    kubernetes_version = "1.33"

    # Habilitar cifrado de secretos de Kubernetes con AWS KMS
    create_kms_key = true
    cluster_encryption_config = {
        resources = ["secrets"]
    }

    # Habilitar observabilidad y auditoría del Control Plane
    cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

    addons = {
        coredns = {}
        eks-pod-identity-agent = {
            before_compute = true
        }
        kube-proxy = {}
        vpc-cni = {
            before_compute = true
        }
    }

    cluster_endpoint_private_access = true

    endpoint_public_access = true
    enable_cluster_creator_admin_permissions = true

    vpc_id = var.vpc_id_main
    subnet_ids = var.private_subnets_ids
    control_plane_subnet_ids = var.private_subnets_ids

    eks_managed_node_groups = {
        example = {
            ami_type = "AL2023_ARM_64_STANDARD"
            instance_types = ["t4g.small"]
            min_size = 1
            max_size = 3
            desired_size = 1
        }
    }

    tags = {
        Environment = var.environment
        Terraform = "true"
    }


    
}