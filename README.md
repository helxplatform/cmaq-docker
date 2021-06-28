# cmaq-docker
Community Multiscale Air Quality Modeling System (CMAQ) docker image

To install Docker on Centos…

 

```

# info from https://docs.docker.com/engine/install/centos/

sudo yum install -y yum-utils

sudo yum-config-manager \

    --add-repo \

    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install docker-ce docker-ce-cli containerd.io

# add docker group and put centos user in it

sudo groupadd docker

sudo usermod -aG docker centos

# enable and start docker service

sudo systemctl enable docker

sudo systemctl start docker

```

After all that you’ll have to log out the centos user and back in so that the centos user’s new addition to the docker group will take effect.

 

Then scp the cmaq.tar.gz file to the EC2 VM at /home/centos/ and extract, then build the Docker image…

```

cd /home/centos

tar -xvzf cmaq.tar.gz

cd cmaq

./build-docker-image.sh

# wait a while (about 45 minutes or so)

# Create cmaq container and get a shell in it.

./run_cmaq.sh

# in container

cd CCTM/scripts

# adjust CPUs

vi run_cctm_singularity.csh

# run benchmark

./run_cctm_singularity.csh
