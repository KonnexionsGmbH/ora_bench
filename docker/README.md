Benchmark Framework for Oracle Database Drivers

# Development Environment `ora_bench_dev` Image

This image supports the use of a Docker container for the further development of `ora_bench` in a Ubuntu environment. 

## 1. Creating a new `ora_bench_dev` Docker container

## 1.1 Getting started

    > REM Assuming the path prefix for the local repository mapping is //C/ora_bench
    > docker run -it \
            --name ora_bench_dev \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v //C/ora_bench:ora_bench \
            konnexionsgmbh/ora_bench_dev
            
    > REM Stopping the container
    > docker stop ora_bench_dev
    
    > REM Restarting the container
    > docker start ora_bench_dev

    > REM Entering a running container
    > docker exec -it ora_bench_dev

## 1.2 Detailed Syntax

A new container can be created with the `docker run` command.

##### Syntax:

    docker run -it 
               [--name <container_name>] \
               -v /var/run/docker.sock:/var/run/docker.sock \
               [-v <directory_repository>:ora_bench] \
               konnexionsgmbh/ora_bench_dev 
               <cmd>
 
##### Parameters:

- **container_name** - an optional container identification 
- **directory_repository** - an optional local repository directory - the default value is expecting the repository inside the container 
- **cmd** - the command to be executed in the container, e.g. `bash` for running the `bash` shell

Detailed documentation for the command `docker run` can be found [here](https://docs.docker.com/engine/reference/run/).

##### Examples:

1. Creating a new Docker container named `ora_bench_dev` using a repository inside the Docker container:  

    `docker run -it --name ora_bench_dev konnexionsgmbh/ora_bench_dev`

2. Creating a new Docker container named `ora_bench_dev` using the local repository in the local Windows directory `D:\SoftDevelopment\Projects\Konnexions\ora_bench_idea\ora_bench`:  

    `docker run -it --name ora_bench_dev -v //D/SoftDevelopment/Projects/Konnexions/ora_bench_idea/ora_bench:/ora_bench konnexionsgmbh/ora_bench_dev`

## 2 Working with an existing `ora_bench_dev` Docker container

### 2.1 Starting a stopped container

A previously stopped container can be started with the `docker start` command.

##### Syntax:

    docker start <container_name>

##### Parameter:

- **container_name** - the mandatory container identification, that is an UUID long identifier, an UUID short identifier or a previously given name 

Detailed documentation for the command `docker start` can be found [here](https://docs.docker.com/engine/reference/commandline/start/).

### 2.2 Entering a running container

A running container can be entered with the `docker exec` command.

##### Syntax:

    docker exec -it <container_name> <cmd>

##### Parameter:

- **container_name** - the mandatory container identification, that is an UUID long identifier, an UUID short identifier or a previously given name 
- **cmd** - the command to be executed in the container, e.g. `bash` for running the `bash` shell

Detailed documentation for the command `docker exec` can be found [here](https://docs.docker.com/engine/reference/commandline/exec/).

## 3 Working inside a running Docker container

### 3.1 `ora_bench_dev` development

Inside the Docker container you can either clone a `ora_bench` repository or switch to an existing `ora_bench` repository. 
If a Docker container with an Oracle database is located on the host computer it can be accessed by using the IP address of the host computer.
Any `ora_bench` script can be executed inside the Docker container, for example:

    ./scripts/run_properties_standard.sh > run_properties_standard.log 2>&1
    
**Important:** If the repository was previously used on Windows, then all files in the following directories must also be deleted from Windows first:

- `src_elixir/deps`  
- `src_elixir/mix.lock`  
- `src_erlang/_build` 

### 3.2 Available software

The Docker Image is based on the latest official Ubunutu Image on Docker Hub, which is currently `20.04`.
With the following command you can check which other software versions are included in the Docker image:

    apt list --installed
