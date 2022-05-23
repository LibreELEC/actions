# Building LibreELEC
## Using GitHub Actions Workflows CI/CD

The LibreELEC Team have developed CI/CD based on **GitHub Actions _Workflows_** to enable **continuous delivery** of *nightly* and *release* **images** and **addons**.

Both tested scenarios below can be deployed to provide support for your **GitHub Actions**.
The customise build guides will help you deploy your **GitHub Action _Runners_** ready to build **LibreELEC**.

- [Build github actions runner/s as docket container/s](build-docker-gha-runner.md)
```mermaid
graph TD;
    ubuntu[ubuntu 22.04 host]-->docker-ubuntu-runner11["Docker ubuntu (inst1)"]
    ubuntu[ubuntu 22.04 host]-->docker-ubuntu-runner12["Docker ubuntu (inst2)"];
    ubuntu[ubuntu 22.04 host]-->docker-ubuntu-runner13["Docker ubuntu (inst3)"];
    ubuntu[ubuntu 22.04 host]-->docker-ubuntu-runner14["Docker ubuntu (inst4)"];
    docker-ubuntu-runner11-->ar11["with actions-runner (inst1)"];
    docker-ubuntu-runner12-->ar12["with actions-runner (inst2)"];
    docker-ubuntu-runner13-->ar13["with actions-runner (inst3)"];
    docker-ubuntu-runner14-->ar14["with actions-runner (inst4)"];
    ar11-->ghaj1((GitHub Workflow Job));
    ar12-->ghaj2((GitHub Workflow Job));
    ar13-->ghaj3((GitHub Workflow Job));
    ar14-->ghaj4((GitHub Workflow Job));
```
- [Deploy a github actions runner on LXC (one per LXC)](build-lxc-gha-runner.md)
```mermaid
graph TD;
    proxmox-->lxc-ubuntu-runner11["LXC ubuntu (runner11)"];
    proxmox-->lxc-ubuntu-runner12["LXC ubuntu (runner12)"];
    proxmox-->lxc-ubuntu-runner13["LXC ubuntu (runner13)"];
    proxmox-->lxc-ubuntu-runner14["LXC ubuntu (runner14)"];
    lxc-ubuntu-runner11-->ar11["with actions-runner (runner11)"];
    lxc-ubuntu-runner12-->ar12["with actions-runner (runner12)"];
    lxc-ubuntu-runner13-->ar13["with actions-runner (runner13)"];
    lxc-ubuntu-runner14-->ar14["with actions-runner (runner14)"];
    ar11-->ghaj1((GitHub Workflow Job));
    ar12-->ghaj2((GitHub Workflow Job));
    ar13-->ghaj3((GitHub Workflow Job));
    ar14-->ghaj4((GitHub Workflow Job));
```

## Information that you should take into consideration before building your repositories **Runners**.

## Future CI/CD
- Contributions are welcome
- Some ideas
- [ ] fix the docker execution to use github syntax
- [ ] simplify calling workflows (nightly-yyy.yml) use as "defaults" style
- [ ] matrix builds
  - https://github.com/AcademySoftwareFoundation/OpenColorIO/blob/4ab4a926f8312d2354a950247a3375dde4992396/.github/workflows/ci_workflow.yml
- [ ] add CI functionality to LE code
- [ ] add capability of make_helper cleaning one directory only
- [ ] logging
  - so we can actually get the logs (as ephemeral means that they are deleted)
  - https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts
  - https://github.com/actions/upload-artifact
