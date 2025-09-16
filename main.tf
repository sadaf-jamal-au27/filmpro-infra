# Create Security Group to allow inbound ports for SSH and Jenkins
resource "aws_security_group" "my_server_sg" {
    name = "myserver-sg"
    description = "Security Group for the EC2 instance"
 
    ingress {
        description = "To allow port 8080"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
 
    egress {
        description = "HTTPS outbound for package updates"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress {
        description = "HTTP outbound for package updates"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress {
        description = "DNS outbound"
        from_port = 53
        to_port = 53
        protocol = "udp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
 
# Data Block to lookup an Ubuntu AMI
data "aws_ami" "my_ami" {
    most_recent = true
    owners = ["099720109477"]
   
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
}

resource "aws_iam_role" "jenkins_role" {
  name = "JenkinsEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
 
resource "aws_iam_instance_profile" "jenkins_profile" {
    name = "jenkins-instance-profile"
    role = aws_iam_role.jenkins_role.name
}
 
# Resource Block to create an EC2 instance
resource "aws_instance" "my_server" {
    ami = data.aws_ami.my_ami.id
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.my_server_sg.id]
    iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
    user_data = file("${path.module}/scripts/install_jenkins.sh")
    monitoring = true
    ebs_optimized = true
    
    metadata_options {
        http_endpoint = "enabled"
        http_tokens = "required"
        http_put_response_hop_limit = 1
        instance_metadata_tags = "enabled"
    }
    
    root_block_device {
        encrypted = true
        volume_type = "gp3"
        volume_size = 8
        delete_on_termination = true
    }

    tags = {
        Name = "myserver"
    }
}