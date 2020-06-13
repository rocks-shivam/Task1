provider "aws" {
  region = "ap-south-1"
  profile = "shivam1"
}
resource "tls_private_key" "mykey" {
  algorithm   = "RSA"
}
output "mykey"{
value = tls_private_key.mykey.public_key_openssh

}
output "mykey2"{
value = tls_private_key.mykey.private_key_pem
}
resource "aws_key_pair" "mykey" {
  key_name   = "newkey"
  public_key = tls_private_key.mykey.public_key_openssh
}
resource "aws_security_group" "mysg" {
depends_on = [
aws_key_pair.mykey,
]
name = "my_security_group"
	description = "Allow http traffic on port 80 and ssh on port 22."

	ingress { 
		description = "http on port 80."
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress { // Check
		description = "ssh on port 22."
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	lifecycle {
		create_before_destroy = true
	}

	tags = {
		Name = "my_task1_sg"
	}
}
resource "aws_instance" "mytask1instance" {
depends_on = [
aws_security_group.mysg,
]
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = aws_key_pair.mykey.key_name
  security_groups = [ aws_security_group.mysg.name]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.mykey.private_key_pem
    host     = aws_instance.mytask1instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "mytaskos"
  }

}


resource "aws_ebs_volume" "extv1" {
depends_on = [
aws_instance.mytask1instance,
]
  availability_zone = aws_instance.mytask1instance.availability_zone
  size              = 1
  tags = {
    Name = "extv1"
  }
}


resource "aws_volume_attachment" "extv1_att" {
depends_on = [
aws_ebs_volume.extv1,
]
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.extv1.id}"
  instance_id = "${aws_instance.mytask1instance.id}"
  force_detach = true
}


output "myos_ip" {
  value = aws_instance.mytask1instance.public_ip
}


resource "null_resource" "local1"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.mytask1instance.public_ip} > publicip.txt"
  	}
}



resource "null_resource" "remote2"  {

depends_on = [
    aws_volume_attachment.extv1_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.mykey.private_key_pem
    host     = aws_instance.mytask1instance.public_ip
  }

provisioner "remote-exec" {
    inline = [
      
      "sudo mkfs.ext4  /dev/xvdf",
      "sudo mkdir /mydata",
      "sudo mount /dev/xvdf /mydata",
      "sudo mount  /dev/xvdf  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/rocks-shivam/mycloud1.git /var/www/html/",
    ]
  }
}



resource "null_resource" "local2"  {


depends_on = [
    null_resource.remote2,
  ]

	provisioner "local-exec" {
	    command = "firefox  ${aws_instance.mytask1instance.public_ip}/file1.html"
  	}
}


