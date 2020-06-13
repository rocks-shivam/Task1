resource "null_resource" "git" {
 provisioner "local-exec" {
      command = "git clone https://github.com/rocks-shivam/s3image.git"
}
provisioner "local-exec" {
      command = "cd .."
}
}


