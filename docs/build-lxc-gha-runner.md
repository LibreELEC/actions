# How to setup a runner from scratch

## Using a LXC as host

### LXC options

 Create a unprivileged LXC with Ubuntu 22.04 as template, enable nesting and keyctl features (needed for Docker).

### Basic setup

> enable console coloring

```shell
sed -i "s/#force_color_prompt=yes/force_color_prompt=yes/" ~/.bashrc && source ~/.bashrc
```

> initial update

```shell
apt update && apt upgrade -y
```

> enable auto updates

```shell
apt install unattended-upgrades -y && dpkg-reconfigure -plow unattended-upgrades
sed -i 's#//\t"${distro_id}:${distro_codename}-updates"#\t"${distro_id}:${distro_codename}-updates"#' /etc/apt/apt.conf.d/50unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
```

> disable password login at ssh

```shell
sed -i "s/^.*PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config && systemctl restart sshd.service
```

### Install Docker

```shell
apt install ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

```shell
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```shell
apt update && apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
```

### Add runner user

> add user

```shell
adduser runner
```

> runner user has sudo rights and is in the docker group

```shell
usermod -aG docker runner && usermod -aG sudo runner
```

> change to the runner user

```shell
su runner
cd
```

### Runner  user changes

> enable console coloring

```shell
sed -i "s/#force_color_prompt=yes/force_color_prompt=yes/" ~/.bashrc && source ~/.bashrc
```

> create ssh key pair

```shell
ssh-keygen
cat ~/.ssh/*.pub
```

> Copy the key to the targeted upload server and do a initial connection to allow the key.

```shell
ssh runner@some.url.com -p 3344
```

> add user keys that are allowed to connect to the runner

```shell
touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
nano ~/.ssh/authorized_keys
```

### Install Github runner

> Add a runner [here at Github](https://github.com/LibreELEC/actions/settings/actions/runners) and follow the description.
Here is just a example, the tokens and versions are different !

```shell
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.291.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.291.1/actions-runner-linux-x64-2.291.1.tar.gz
tar xzf ./actions-runner-linux-x64-2.291.1.tar.gz
./config.sh --url https://github.com/LibreELEC/actions --token 1234567890123456789
```

> install the Github runner service and enable it

```shell
sudo ./svc.sh install
sudo systemctl enable actions.runner.LibreELEC-actions.$(hostnamectl hostname).service
sudo systemctl start actions.runner.LibreELEC-actions.$(hostnamectl hostname).service
sudo systemctl status actions.runner.LibreELEC-actions.$(hostnamectl hostname).service
```

> create the needed paths and allow the runner to write in it

```shell
sudo mkdir -p /var/media/DATA/github-actions/{build-root,sources,target}
sudo chown runner:runner /var/media/DATA/github-actions/{build-root,sources,target}
```

Done :)
