# Building LibreELEC
## Using GitHub Actions Workflows CI/CD
- [Build github actions runner/s as docket container/s](build-docker-gha-runner.md)
```mermaid
graph TD;
    ubuntu-->docker-ubuntu-runner11;
    ubuntu-->docker-ubuntu-runner12;
    ubuntu-->docker-ubuntu-runner13;
    ubuntu-->docker-ubuntu-runner14;
```
- [Deploy a github actions runner on LXC (one per LXC)](build-lxc-gha-runner.md)
```mermaid
graph TD;
    proxmox-->lxc-ubuntu-runner11;
    proxmox-->lxc-ubuntu-runner12;
    proxmox-->lxc-ubuntu-runner13;
    proxmox-->lxc-ubuntu-runner14;
    lxc-ubuntu-runner11-->runner11-process;
    lxc-ubuntu-runner12-->runner12-process;
    lxc-ubuntu-runner13-->runner13-process;
    lxc-ubuntu-runner14-->runner14-process;
```
