#!/bin/sh
set -eu

cat <<'EOF'
Paste these commands into the FreeBSD root console, then run `mise run opencloud:build` again:

pw useradd vagrant -m -s /bin/sh -G wheel || true
printf 'vagrant\nvagrant\n' | passwd vagrant
printf 'vagrant\nvagrant\n' | passwd root
sysrc sshd_enable=YES
mkdir -p /home/vagrant/.ssh
cat > /home/vagrant/.ssh/authorized_keys <<'KEY'
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
KEY
chown -R vagrant:wheel /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/authorized_keys
sed -i '' 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i '' 's/^#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
service sshd restart || service sshd start

EOF
