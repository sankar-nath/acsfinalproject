#key used to login to ec2 instance to setup httpd
resource "aws_key_pair" "acs_proj_key" {
  key_name   = "acs_project_key"
  public_key = file("../keys/acs_project.pub")
}
