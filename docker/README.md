# Docker Usage

This project supports the use of Docker for development in a current Ubuntu environment. 
For this purpose, either the script `run_create_image_ora_bench_dev` and the Docker file in the directory `priv/docker` can be used to create a special Docker image or the existing Docker image `konnexionsgmbh/ora_bench_dev` available in the Docker Hub can be downloaded and used.

The following assumes that the default name `ora_bench_dev' is used for the Docker image and for the Docker container.

## 1 Create Docker image from scratch

1. If required, the Docker file in the directory `docker` can be customized.
2. If uploading the Docker image to the Docker Hub is not desired, then the `docker push konnexionsgmbh/%REPOSITORY%` command must be commented out in the script `run_create_image_ora_bench_dev`.
3. Run the script `run_create_image_ora_bench_dev`.
4. After successful execution (see log file `run_create_image_ora_bench_dev.log`) the Docker container `ora_bench_dev` is running and can be used with the Bash Shell for example (see chapter 6.3).

## 2 Use Docker image from Docker Hub

An image that already exists on Docker Hub can be downloaded as follows:

    docker pull konnexionsgmbh/ora_bench_dev

## 3 Working with an existing Docker image

### 3.1 Creating the Docker container

First the Docker container must be created and started  (Example for a data directory: `D:\SoftDevelopment\Projects\Konnexions\ora_bench_idea\ora_bench`):

    docker run -it --name ora_bench_dev -v /var/run/docker.sock:/var/run/docker.sock -v <data directory path>:/ora_bench konnexionsgmbh/ora_bench_dev bash

Afterwards you are inside the Docker container.

### 3.2 Starting an existing Docker container

You can start an existing Docker container as follows

    docker start ora_bench_dev

This command switches into the running Docker container:

    docker exec -it ora_bench_dev bash

## 4 Working inside a running Docker container

Inside the Docker container you can switch to the ora_bench repository with the following command:

    cd ora_bench

The Docker container with the Oracle database is located on the host computer and can be accessed using the IP address of the host computer:

    export ORA_BENCH_CONNECTION_HOST=<IP address of the host computer> 

Now any `ora_bench` script can be executed, for example:

    ./scripts/run_db_setup_benchmark_props_std.sh 

Elixir requires special treatment for 'rebar3'. The question `Shall I install rebar3?` must be answered with `Y`:

	Setup Elixir - Start =======================================================
	Resolving Hex dependencies...
	Dependency resolution completed:
	Unchanged:
	  connection 1.0.4
	  db_connection 2.2.0
	  decimal 1.8.1
	  ecto 3.2.5
	  ecto_sql 3.2.2
	  telemetry 0.4.1
	All dependencies are up to date
	Could not find "rebar3", which is needed to build dependency :telemetry
	I can install a local copy which is just used by Mix
	Shall I install rebar3? (if running non-interactively, use "mix local.rebar --force") [Yn]

