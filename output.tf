output "ansible-ip" {
  value = aws_instance.ansible_instance.public_ip
}
output "redhat-ip" {
  value = aws_instance.redhat.public_ip
}
output "ubuntu-ip" {
  value = aws_instance.ubuntu.public_ip
}
