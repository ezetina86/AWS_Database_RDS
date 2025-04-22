# Database on RDS (Estimated time: 5h)

## Agenda

In this lab we will replace built-in Ghost's database with RDS-based to share data between application instances. 

To achieve this we will need to create some resources:
- Subnets and database subnets groups
- Security group
- RDS Database using MySQL engine 
- Store DB admin password in SSM Parameter Store
- Update IAM role
- Update launch template

For this lab you will need basic infrastructure from [Basic Infrastructure](./task1_basic_infra.md). You can easly create it with code from [Infrastructure as code](./task2_iac.md). 

The additional resources are recommended to be used for IaC implementation ([Infrastructure as code](./task2_iac.md)). 

<details>
<summary> Terraform </summary>

#### Database
- [aws_db_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group)
- [aws_db_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
</details>

<details>
<summary> AWS CloudFormation </summary>

#### Database
- [AWS::RDS::DBParameterGroup](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-rds-dbparametergroup.html)
- [AWS::RDS::DBInstance](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-rds-database-instance.html)
</details>

## Infrastructure Diagram:
![chart](./images/ExternalDataBase.png)

## 1 - Add private subnets for DB

- 3 x Database subnets(private):
  - name=private_db_a, cidr=10.10.20.0/24, az=a
  - name=private_db_b, cidr=10.10.21.0/24, az=b
  - name=private_db_c, cidr=10.10.22.0/24, az=c
- Routing table and attach it with the Private subnets (name=private_rt)

## 2 - Add security groups for DB

Add the following security group:

- name=mysql, description="defines access to ghost db":
  - ingress rule_1: port=3306, source_security_group={ec2_pool}, protocol=tcp
  - Hint: Check that `egress rule` is in place.

## 3 - Create Database

Create DB related resources:

- Subnet_group:
  - name=ghost, subnet_ids={private_db_a,private_db_b,private_db_c}, description='ghost database subnet group'

- MySQL Database:
  - name=ghost, instance_type=db.t2.micro, engine_version=8.0, storage=gp2, allocated_space=20Gb, security_groups={mysql}, subnet_groups={ghost}

## 4 - Store DB password in a safe way

Generate DB password and store in SSM Parameter store as secure string(name=/ghost/dbpassw).

## 5 - Update IAM role

Update IAM Role, add new permissions:

```
"ssm:GetParameter*",
"secretsmanager:GetSecretValue",
"kms:Decrypt"
```

This permissions provide EC2 instances access to SSM Parameter Store.

## 6 - Update Launch Template

Refine script according to the latest changes:
- Install pre-requirements
- Install, configure and run Ghost application
- Read DB password from the secret store

<details>
  <summary markdown="span">Script example(click to expand):</summary>

```
#!/bin/bash -xe
exec > >(tee /var/log/cloud-init-output.log|logger -t user-data -s 2>/dev/console) 2>&1

### Update this to match your ALB DNS name
LB_DNS_NAME='url.region.elb.amazonaws.com'
###
SSM_DB_PASSWORD="/ghost/dbpassw"
REGION=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
DB_PASSWORD=$(aws ssm get-parameter --name $SSM_DB_PASSWORD --query Parameter.Value --with-decryption --region $REGION --output text)

curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
yum install -y nodejs amazon-efs-utils
npm install ghost-cli@latest -g

adduser ghost_user
usermod -aG wheel ghost_user
cd /home/ghost_user/

sudo -u ghost_user ghost install local

### EFS mount
mkdir -p /home/ghost_user/ghost/content/data
mount -t efs -o tls $EFS_ID:/ /home/ghost_user/ghost/content

cat << EOF > config.development.json

{
  "url": "http://${LB_DNS_NAME}",
  "server": {
    "port": 2368,
    "host": "0.0.0.0"
  },
  "database": {
    "client": "mysql",
    "connection": {
        "host": "${DB_URL}",
        "port": 3306,
        "user": "${DB_USER}",
        "password": "$DB_PASSWORD",
        "database": "${DB_NAME}"
    }
  },
  "mail": {
    "transport": "Direct"
  },
  "logging": {
    "transports": [
      "file",
      "stdout"
    ]
  },
  "process": "local",
  "paths": {
    "contentPath": "/home/ghost_user/ghost/content"
  }
}
EOF

sudo -u ghost_user ghost stop
sudo -u ghost_user ghost start
```

</details>

## Definition of done

After changing configuration to use RDS MySQL database you can successfully open your Ghost app on browser by ALB URL.

## Clean-up

Do not forget to stop and delete your resources on the end of practice. You can use Tags to locate required resources.
