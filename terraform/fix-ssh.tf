# Temporary fix: Allow SSH from anywhere for troubleshooting
# WARNING: This is less secure. Restrict after troubleshooting.

# Add a separate SSH rule that allows from anywhere
# This is in addition to the existing restricted rule
resource "aws_security_group_rule" "ssh_anywhere" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.smartdns_sg.id
  description       = "Temporary: Allow SSH from anywhere for troubleshooting"
}
