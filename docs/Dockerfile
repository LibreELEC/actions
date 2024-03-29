FROM ubuntu:focal
ARG DEBIAN_FRONTEND=noninteractive
ARG GH_ACTIONS_TOKEN
ARG INST_WORK
ARG INST_NAME

RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install -y locales sudo

RUN locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN adduser --disabled-password --gecos '' docker \
 && adduser docker sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install docker
RUN apt-get install -y \
    ca-certificates curl gnupg lsb-release \
    --no-install-recommends
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    --no-install-recommends

# packages required for github actions-runner
RUN apt-get install -y git --no-install-recommends
RUN apt-get install -y libicu66 liblttng-ust-ctl4 liblttng-ust0 libnuma1 liburcu6

USER docker

# Download the latest runner package

WORKDIR /home/docker
RUN mkdir actions-runner && cd actions-runner \
    && curl -o actions-runner-linux-x64-2.290.1.tar.gz \
       -L https://github.com/actions/runner/releases/download/v2.290.1/actions-runner-linux-x64-2.290.1.tar.gz \
    && tar xzf ./actions-runner-linux-x64-2.290.1.tar.gz

WORKDIR /home/docker/actions-runner
RUN sudo ./bin/installdependencies.sh \
    && ./config.sh --url https://github.com/LibreELEC/actions --token $GH_ACTIONS_TOKEN --work "/var/media/DATA/github-actions/$INST_WORK" --name "$INST_NAME" < /dev/null

# call run.sh twice, so that during upgrade it updates in place
# a better approach would be a loop - but need to set a timer / handler so that on a real
# failure of the run.sh - it doesnt continue to loop on itself.
RUN echo "sudo chgrp docker /var/run/docker.sock" > /home/docker/runme.sh \
    && echo "(cd /home/docker/actions-runner; ./run.sh; ./run.sh)" >> /home/docker/runme.sh \
    && chmod 755 /home/docker/runme.sh

# USE THIS TO RUN THE CONTAINER (instance 3)
#
# docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock \
#   -v /var/media/DATA/github-actions:/var/media/DATA/github-actions 
#   -it github-runner3:latest bash /home/docker/runme.sh
#
# USE THIS TO CREATE THE IMAGE (instance 3)
# docker build --pull -t github-runner3 --build-arg GH_ACTIONS_TOKEN=<token_goes_here> 
#   --build-arg INST_WORK=_inst3_work --build-arg INST_NAME=nuc10_inst3 github-runner
