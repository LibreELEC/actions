### Ideas / TODO - something for the future

- how do we update slack?
- matrix builds
  - https://github.com/AcademySoftwareFoundation/OpenColorIO/blob/4ab4a926f8312d2354a950247a3375dde4992396/.github/workflows/ci_workflow.yml
- update nightly-LE10 to include all targets
- change names of files to drop lubreelec?
- create nightly-LE10-addon.yml
- create release-LE10.yml
- test logic for export CCACHE_DISABLE=1
- logging - so we can actually get the logs (as ephemeral means that they are deleted)
- on cancelled jobs ... how to cleanup?
- The difference between workflows is now minimal (how to migrate to using Reusable workflows /	Composite actions)
  - https://github.blog/2022-02-10-using-reusable-workflows-github-actions/
- How can we use "CI=yes"
- could be smarter and build the docker base that is then subsequently used with the .config ???
- Do we have need for environments ?
  - Private Repo's dont allow Environments.
- fix the docker execution to use github syntax
  - parameterise the `make image` (addons is done- but need to change to buildcmd and update other .yml files so we can have the single template /include.


```
--- libreelec-A64_arm.yml       2022-05-10 13:32:55.815176539 +0000
+++ libreelec-Generic_x86_64-10_0.yml   2022-05-10 13:32:26.501891262 +0000
@@ -1,4 +1,4 @@
-name: libreelec-A64_arm
+name: libreelec-Generic_x86_64-10_0
 on:
   # allows to run this workflow manually from the actions tab
   workflow_dispatch:
@@ -65,13 +65,13 @@
   TZ: Australia/Melbourne
   BASEDIR: /var/media/DATA/github-actions
   # Distro Target Variables
-  PROJECT: Allwinner
-  ARCH: arm
-  DEVICE: A64
-  TARGETBUILDDIR: build.LibreELEC-A64.arm-11.0-devel
+  PROJECT: Generic
+  ARCH: x86_64
+  #DEVICE: Generic ### LE10 does not support DEVICE for PROJECT=Generic
+  TARGETBUILDDIR: build.LibreELEC-Generic.x86_64-10.0-devel

 concurrency:
-  group: A64_arm
+  group: Generic_x86_64-10_0
   cancel-in-progress: false

 jobs:
@@ -81,7 +81,7 @@
     steps:
       - uses: actions/checkout@v3
         with:
-          ref: master
+          ref: libreelec-10.0
           fetch-depth: 2
           repository: "LibreELEC/LibreELEC.tv"
           path: "LibreELEC.tv"
@@ -93,7 +93,7 @@
           sed -i -e "s/RUN adduser/RUN adduser --uid $(id -u)/" tools/docker/focal/Dockerfile
           # workaround below until buildsystem does not require local cc
           #sed -i -e "/^USER docker/i RUN ln -s /usr/bin/gcc-10 /usr/bin/cc" tools/docker/focal/Dockerfile
-          #sed -i -e 's/^CCACHE_CACHE_SIZE=.*/CCACHE_CACHE_SIZE="30G"/' config/options
+          sed -i -e 's/^CCACHE_CACHE_SIZE=.*/CCACHE_CACHE_SIZE="30G"/' config/options
           docker build --pull -t gh-${{ github.run_id }} tools/docker/focal

       - name: Prepare the LibreELEC.tv directory - setup /sources
@@ -154,7 +154,6 @@
                           -w /build -i \
                           -e PROJECT=${{ env.PROJECT }} \
                           -e ARCH=${{ env.ARCH }} \
-                          -e DEVICE=${{ env.DEVICE }} \
                           -e ONELOG=no -e LOGCOMBINE=never \
                           -e BUILD_DIR=${{ env.build_dir }} \
                           gh-${{ github.run_id }} make image
```

## Fixes done to runners:
```
sudo chown runner:runner /var/media/DATA/github-actions/{build-root,sources,target}
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
tune2fs -l /dev/ubuntu-vg/ubuntu-lv | egrep "Block size:|Reserved block count"
tune2fs -m 1 /dev/ubuntu-vg/ubuntu-lv
tune2fs -l /dev/ubuntu-vg/ubuntu-lv | egrep "Block size:|Reserved block count"
resize2fs /dev/ubuntu-vg/ubuntu-lv
df
# ssh host key to scp / ssh targets
# sync the sources directories
```

### Ideas - DONE
- continue-on-error -- addons
- hexdump is required for the addon retro builds -- look at util-linux
- enable cron in https://github.com/LibreELEC/actions/blob/b7ab83ba173a2751ee244e783ec2289e4d43d866/.github/workflows/nightly-MASTER.yml#L5-L7
- ~inputs. dont come across from workflow_run :-(~
- ~so next task will be to look at the "CI=yes" and seeing what the correct way to call the workflows is? (https://github.com/heitbaum/libreelec-actions/blob/main/.github/workflows/libreelec-nightly.yml is setup to initiate all using workflow_run) - is workflow_call the right way? https://github.blog/2022-02-10-using-reusable-workflows-github-actions/~
  - ~https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows~
- ~use concurrecy groups to stop same build target concurrency builds.~
  - ~https://github.blog/changelog/2021-04-19-github-actions-limit-workflow-run-or-job-concurrency/~
  - ~DONE~
- ~do the nightly runs~
  - ~https://stackoverflow.com/questions/63014786/how-to-schedule-a-github-actions-nightly-build-but-run-it-only-when-there-where~
  - ~https://gist.github.com/jasonrudolph/1810768~
  - ~might need to have a prescript to is dispatch that checks bbefore spawning ....~
- ~how to spawn all the workflows~
  - ~use workflow_run~
    - ~https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_run~
  - ~use workflow_dispatch~
  - ~github actions workflow dispatch~
  - ~https://docs.github.com/en/actions/using-workflows/triggering-a-workflow#triggering-a-workflow-from-a-workflow~
  - ~https://github.blog/2022-02-10-using-reusable-workflows-github-actions/~
- ~reusable workflows~
  - ~https://yonatankra.com/7-github-actions-tricks-i-wish-i-knew-before-i-started/~
- ~other stuff: / subworkflow / actions~
  - ~https://github.com/actions/runner/discussions/1419?msclkid=b3843972cf3711ecbe5439078f5daf4c~
  - ~https://github.github.io/actions-cheat-sheet/actions-cheat-sheet.pdf~
  - ~https://www.bing.com/search?q=github+%22uses%22+same+repository&cvid=60fe0aef5c1549db9efa12bca84795ea&aqs=edge..69i57j69i64l2.15260j0j1&FORM=ANAB01&PC=U531~
  - ~https://docs.github.com/en/actions/using-workflows/reusing-workflows#creating-a-reusable-workflow~
- get uploads to work
  - you will need to update this from `no_upload` to `upload` to run the test.
  - you need to update all on the with: blocks in the job: section. Don't worry about L15-L16 in env: (not used at the moment)  
  - https://github.com/LibreELEC/actions/blob/a760ba7cd44d1d3d73d9b9904450e4e503f47a1e/.github/workflows/nightly-MASTER.yml#L49-L50
- update the other workflows (not Generic-10.0, A64, H3, H5, H6, AMLGX, addons -- these are done...) to updated template.
- update nightly-MASTER to include all targets
- remove commented-out from `if: checkdate` - TESTING required https://github.com/LibreELEC/actions/blob/9afe68eed6cbf879daa8ede4fb8a8da84c34ba53/.github/workflows/nightly-LE10.yml#L39
- check the commit hash / date logic --- issue was using the "actions repo" not the "LibreELEC.tv" repo

### Current status / things to understand / work though
- there is only 1 (shared) build-root (dont buiuld the same architecture at the same time - it will lock / fail)
  - it will handle building without clean/distclean, if it needs to be cleaned - then call clean
  - need to adjust clean to clean for a specific directory `build.LibreELEC-Generic.x86_64-11.0-devel`
- there are unique _instX_work directories per image (container)
  - only start one of each image !!! 
  - each image  has the unique key to connect to github
- there is a shared source directory
- there is a shared target directory


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

### Build host details
```
$ dmesg | grep NUC
[    0.000000] DMI: Intel(R) Client Systems NUC10i7FNH/NUC10i7FNB, BIOS FNCML357.0045.2020.0817.1709 08/17/2020

$ lscpu
Architecture:            x86_64
  CPU op-mode(s):        32-bit, 64-bit
  Address sizes:         39 bits physical, 48 bits virtual
  Byte Order:            Little Endian
CPU(s):                  12
  On-line CPU(s) list:   0-11
Vendor ID:               GenuineIntel
  Model name:            Intel(R) Core(TM) i7-10710U CPU @ 1.10GHz
  
$ top - 11:43:05 up  1:17,  3 users,  load average: 19.37, 18.80, 16.68
Tasks: 334 total,  10 running, 324 sleeping,   0 stopped,   0 zombie
%Cpu(s): 69.8 us, 11.0 sy,  0.0 ni, 19.2 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  64151.6 total,  30210.1 free,   2065.9 used,  31875.6 buff/cache
MiB Swap:   8192.0 total,   8192.0 free,      0.0 used.  61326.6 avail Mem

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
1907015 docker    20   0   98176  83668  24100 R 100.0   0.1   0:04.02 cc1
1903817 docker    20   0   71920  68908   5148 R 100.0   0.1   0:05.62 automake
1906621 docker    20   0  354880 324168  18116 R 100.0   0.5   0:04.36 cc1plus
```

### OTHER STUFF - NOTES to self only

https://devopscube.com/run-docker-in-docker/

```
sudo chgrp docker /var/run/docker.sock
nuc11:~ # mkdir /var/media/DATA/github-actions
nuc11:~ # chown 1000:1000 /var/media/DATA/github-actions
nuc11:~ # cp -dpR LibreELEC.tv/sources /var/media/DATA/github-actions/

# build the github runner (use github-runner/Dockerfile)
docker build --pull -t github-runner github-runner

```

The you can `docker@1a46680e167f:~/actions-runner$ ./run.sh` from within the docker. 
Or `docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock -v /var/media/DATA/github-actions:/var/media/DATA/github-actions -it github-runner:latest sh /home/docker/runme.sh` from the host.




```
docker@nuc10:/var/media/DATA/github-actions/build-root$ du -sk build.LibreELEC-*/.ccache
8703084 build.LibreELEC-A64.arm-11.0-devel/.ccache
6854936 build.LibreELEC-AMLGX.arm-11.0-devel/.ccache
6419692 build.LibreELEC-ARMv7.arm-11.0-devel/.ccache
10498440        build.LibreELEC-ARMv8.arm-11.0-devel/.ccache
6489000 build.LibreELEC-Dragonboard.arm-11.0-devel/.ccache
5251904 build.LibreELEC-Exynos.arm-11.0-devel/.ccache
2173672 build.LibreELEC-Generic-legacy.x86_64-11.0-devel/.ccache
12722212        build.LibreELEC-Generic.x86_64-10.0-devel/.ccache
15134548        build.LibreELEC-Generic.x86_64-11.0-devel/.ccache
4970944 build.LibreELEC-H3.arm-11.0-devel/.ccache
6881820 build.LibreELEC-H5.arm-11.0-devel/.ccache
6885004 build.LibreELEC-H6.arm-11.0-devel/.ccache
5637312 build.LibreELEC-RK3288.arm-11.0-devel/.ccache
6729636 build.LibreELEC-RK3328.arm-11.0-devel/.ccache
6884028 build.LibreELEC-RK3399.arm-11.0-devel/.ccache
4806360 build.LibreELEC-RPi2.arm-11.0-devel/.ccache
5470812 build.LibreELEC-RPi4.arm-11.0-devel/.ccache
4836524 build.LibreELEC-iMX6.arm-11.0-devel/.ccache
5467764 build.LibreELEC-iMX8.arm-11.0-devel/.ccache

docker@nuc10:/var/media/DATA/github-actions/build-root$ du -sk build.LibreELEC-*
36894332        build.LibreELEC-A64.arm-11.0-devel
29498308        build.LibreELEC-AMLGX.arm-11.0-devel
41924012        build.LibreELEC-ARMv7.arm-11.0-devel
49009676        build.LibreELEC-ARMv8.arm-11.0-devel
31943652        build.LibreELEC-Dragonboard.arm-11.0-devel
26089792        build.LibreELEC-Exynos.arm-11.0-devel
4003980 build.LibreELEC-Generic-legacy.x86_64-11.0-devel
41381216        build.LibreELEC-Generic.x86_64-10.0-devel
67157228        build.LibreELEC-Generic.x86_64-11.0-devel
26280972        build.LibreELEC-H3.arm-11.0-devel
35145592        build.LibreELEC-H5.arm-11.0-devel
35074892        build.LibreELEC-H6.arm-11.0-devel
24932536        build.LibreELEC-RK3288.arm-11.0-devel
33263044        build.LibreELEC-RK3328.arm-11.0-devel
32914840        build.LibreELEC-RK3399.arm-11.0-devel
24283028        build.LibreELEC-RPi2.arm-11.0-devel
28172412        build.LibreELEC-RPi4.arm-11.0-devel
23758228        build.LibreELEC-iMX6.arm-11.0-devel
28114568        build.LibreELEC-iMX8.arm-11.0-devel
docker@nuc10:/var/media/DATA/github-actions/build-root$ df
Filesystem                         1K-blocks      Used  Available Use% Mounted on
tmpfs                                6569124      2212    6566912   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  102626232  20033056   77333912  21% /
tmpfs                               32845600         0   32845600   0% /dev/shm
tmpfs                                   5120         0       5120   0% /run/lock
/dev/nvme0n1p2                       1992552    128256    1743056   7% /boot
/dev/nvme0n1p1                       1098632      5364    1093268   1% /boot/efi
/dev/mapper/ubuntu--vg-data       1815361124 669129744 1146214996  37% /var/media/DATA
tmpfs                                6569120         4    6569116   1% /run/user/1000

```
