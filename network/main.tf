#initial networking deployment 

#ami we will use for our ec2 instances
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "globalVars" {
  source = "../modules/globalVars"
}

# AWS VPC deployment
module "vpc-dev" {
  source              = "../modules/network"
  env                 = var.env
  vpc_cidr            = var.vpc_cidr
  public_cidr_blocks  = var.public_subnet_cidrs
  private_cidr_blocks = var.private_subnet_cidrs
  prefix              = module.globalVars.prefix
  default_tags        = var.default_tags
}

# Module to deploy application loadbalancer
module "loadBalancer" {
  source                    = "../modules/loadBalancer"
  env                       = var.env
  prefix                    = module.globalVars.prefix
  vpc_id                    = module.vpc-dev.vpc_id
  public_subnet             = module.vpc-dev.public_subnet_ids
  private_subnet            = module.vpc-dev.private_subnet_ids
  bastion_security_group_id = module.bastion.bastion_security_group_id
}


# Module to deploy Auto scaling group
module "autoScalingGroup" {
  source           = "../modules/autoScalingGroup"
  env              = var.env
  prefix           = module.globalVars.prefix
  target_group_arn = module.loadBalancer.target_group
  vpc_id           = module.vpc-dev.vpc_id
  public_subnet    = module.vpc-dev.public_subnet_ids
  private_subnet   = module.vpc-dev.private_subnet_ids
  security_groups  = [module.loadBalancer.security_groups]
  min_size         = var.min_size
  max_size         = var.max_size
  instance_type    = var.instance_type
  instance_ami     = data.aws_ami.latest_amazon_linux.id
  key_name         = module.aws_key.key_name
  desired_capacity = var.desired_capacity
  members          = module.globalVars.members
}


# create AWS key
module "aws_key" {
  source   = "../modules/awsKeys"
  key_name = "${var.prefix}-${var.env}-key"
  key_path = abspath("../keys/acs_project.pub")
}

#bastion deployment
module "bastion" {
  source            = "../modules/bastion"
  env               = var.env
  prefix            = module.globalVars.prefix
  instance_ami      = data.aws_ami.latest_amazon_linux.id
  key_name          = module.aws_key.key_name
  instance_type     = var.instance_type
  vpc_id            = module.vpc-dev.vpc_id
  bastion_subnet_id = module.vpc-dev.public_subnet_ids[0]
}