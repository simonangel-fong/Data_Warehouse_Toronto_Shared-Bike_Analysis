


- Ref:
  - https://www.jenkins.io/doc/book/installing/linux/#red-hat-centos

```sh
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum repolist
sudo yum upgrade -y
# Add required dependencies for the jenkins package
sudo yum install -y fontconfig java-17-openjdk
update-alternatives --config java
# confirm
java --version

sudo yum install -y jenkins

sudo systemctl daemon-reload

sudo systemctl enable --now jenkins
sudo systemctl status jenkins

firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
```

- Configuring Jenkins

```sh
cat var/lib/jenkins/secrets/initialAdminPassword
```

- Create Admin user
  - Username: devopsAdmin
  - pwd: devopsAdmin123