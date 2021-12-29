# How to setup a runner from scratch

## Using a Ubuntu / Docker as host

### Install ubuntu 22.04 (without docker but with openssh) on the physical hardware.
- the userid choosen to be created on the ubuntu was `docker`
- Install docker on the ubuntu host
  - https://docs.docker.com/engine/install/ubuntu/#installation-methods

```
sudo apt-get update

sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### Prepare the DATA filesystem 
- Create the /var/media/data filesystem
  - `lvcreate -l 100%FREE -n data ubuntu-vg`
  - `mkfs.ext4 -m 0 /dev/ubuntu-vg/data`
  - `echo "/dev/disk/by-id/dm-name-ubuntu--vg-data /var/media/DATA ext4 rw,relatime 0 1" >> /etc/fstab`
  - `mkdir -p /var/media/DATA`
  - `mount /var/media/DATA`
  - `mkdir -p /var/media/DATA/github-actions/{build-root,sources,target}`
  - `chown -R docker:docker /var/media/DATA/github-actions`

### Create the instance 3 of the docker:

```
GH_ACTIONS_TOKEN=<replace_with_token>
docker build --pull -t github-runner3 --build-arg GH_ACTIONS_TOKEN=${GH_ACTIONS_TOKEN} \
  --build-arg INST_WORK=_inst3_work \
  --build-arg INST_NAME=nuc10_inst3 \
  github-runner
```

### to check your inst3 runner is correct:
```
docker run --log-driver none -it github-runner3:latest cat /home/docker/actions-runner/.runner
{
  "agentId": 32,
  "agentName": "nuc10_inst3",
  "poolId": 1,
  "poolName": "Default",
  "serverUrl": "https://pipelines.actions.githubusercontent.com/xxx",
  "gitHubUrl": "https://github.com/heitbaum/libreelec-actions",
  "workFolder": "/var/media/DATA/github-actions/_inst3_work"
}
```

### Run instance 3 of the runner as a daemon (see -d):
Note the instance 3 = `github-runner3`

```
docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/media/DATA/github-actions:/var/media/DATA/github-actions \
  -d -it github-runner3:latest bash /home/docker/runme.sh
```

### cleanup images
```
docker image rm -f github-runner1
docker image rm -f github-runner2
docker image rm -f github-runner3
docker image rm -f github-runner4
```

### Build more instances:
```
GH_ACTIONS_TOKEN=<replace_with_token>
docker build --pull -t github-runner1 --build-arg GH_ACTIONS_TOKEN=${GH_ACTIONS_TOKEN} \
  --build-arg INST_WORK=_inst1_work --build-arg INST_NAME=nuc10_inst1 github-runner
  
docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/media/DATA/github-actions:/var/media/DATA/github-actions \
  -d -it github-runner1:latest bash /home/docker/runme.sh

docker build --pull -t github-runner2 --build-arg GH_ACTIONS_TOKEN=${GH_ACTIONS_TOKEN} \
  --build-arg INST_WORK=_inst2_work --build-arg INST_NAME=nuc10_inst2 github-runner
  
docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/media/DATA/github-actions:/var/media/DATA/github-actions \
  -d -it github-runner2:latest bash /home/docker/runme.sh
  
docker build --pull -t github-runner4 --build-arg GH_ACTIONS_TOKEN=${GH_ACTIONS_TOKEN} \
  --build-arg INST_WORK=_inst4_work --build-arg INST_NAME=nuc10_inst4 github-runner
  
docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/media/DATA/github-actions:/var/media/DATA/github-actions \
  -d -it github-runner4:latest bash /home/docker/runme.sh
```

### create an /etc/rc.local file on the ubuntu
```
touch /etc/rc.local
chmod 755 /etc/rc.local
echo "#!/bin/sh" > /etc/rc.local
# add the docker startups to the rc.local
vi /etc.rc.local 

systemctl status rc-local
systemctl enable rc-local
systemctl start rc-local
```

### Check that your containers are running
```
docker@nuc10:~$ docker ps
CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS          PORTS     NAMES
91cfd57dc4dd   github-runner1:latest   "bash /home/docker/r…"   11 seconds ago   Up 10 seconds             exciting_nightingale
f1fdeb68c519   github-runner4:latest   "bash /home/docker/r…"   54 seconds ago   Up 53 seconds             quirky_easley
f3782edf1a7a   github-runner2:latest   "bash /home/docker/r…"   7 minutes ago    Up 7 minutes              peaceful_neumann
b09900fb96e3   gh-libreelec            "make image"             42 minutes ago   Up 42 minutes             angry_mclaren
59c876a3c059   github-runner3:latest   "bash /home/docker/r…"   46 minutes ago   Up 46 minutes             crazy_lalande
```

https://github.com/heitbaum/libreelec-actions/settings/actions/runners

![image](https://user-images.githubusercontent.com/6086324/166673305-ab244d1d-bec3-4f37-8287-ad359f484b3b.png)

### Execute a run

![image](https://user-images.githubusercontent.com/6086324/166674391-609e3227-3929-4215-bc71-916aff6548c8.png)

### Check the build host:
```
docker@nuc10:/var/media/DATA/github-actions$ ls -l *
_inst3_work:
total 28
drwxr-xr-x 3 docker docker 4096 May  4 10:46 _PipelineMapping
drwxr-xr-x 4 docker docker 4096 May  4 10:46 _actions
drwxr-xr-x 4 docker docker 4096 May  4 10:48 _temp
drwxr-xr-x 2 docker docker 4096 May  4 10:46 _tool
drwxr-xr-x 3 docker docker 4096 May  4 10:46 libreelec-actions

build-root:
total 12
drwxr-xr-x 12 docker docker 4096 May  4 11:26 build.LibreELEC-Generic.x86_64-11.0-devel

sources:
total 552
drwxr-xr-x   2 docker docker 4096 May  4 10:59 Jinja2
drwxr-xr-x   2 docker docker 4096 May  4 11:00 Mako
...

target:
total 8
...
```
