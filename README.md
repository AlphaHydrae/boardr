# Boardr

A distributed web application to play board games.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Disclaimer](#disclaimer)
- [Contents](#contents)
  - [HTTP API backend](#http-api-backend)
  - [Single-page application frontend](#single-page-application-frontend)
  - [Load testing](#load-testing)
  - [Local Vagrant environment](#local-vagrant-environment)
  - [Raspberry Pi cluster](#raspberry-pi-cluster)
- [Requirements](#requirements)
  - [Runtime](#runtime)
  - [Database](#database)
- [Development](#development)
  - [Backend](#backend)
  - [Frontend](#frontend)
- [TODO](#todo)
  - [Documentation](#documentation)
  - [Roadmap](#roadmap)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## Disclaimer

This repository is a work in progress. It contains a pile of *unholy*
experiments on my journey to learn [Elixir][elixir] and [Elm][elm], and to try
to make things fit together that should not. It barely holds together. **Do not,
under any circumstances**, take any of this code within one hundred feet of any
production system. **You have been warned.**



## Contents

The mess in this repository.

### HTTP API backend

The [`server` directory](./server) contains the application's backend written in
[Elixir][elixir].

* The application is an [Elixir Umbrella project][elixir-umbrella] split into a
  "business" application in `server/apps/boardr` and the HTTP API in
  `server/apps/boardr_api`.
* The HTTP API is a hypermedia REST API using the [HAL+JSON format][hal].
* Errors are intended to be in the standard format described by the [Problem
  Details for HTTP APIs RFC][http-problem-details], although all error handling
  in this project is a work in progress.

### Single-page application frontend

The [`client` directory](./client) contains the application's frontend written
in [Elm][elm].

### Load testing

This repository contains a load-testing scenario for the application, written
with [Locust.io][locust].

* The code is in the [`load-testing` directory](./load-testing).
* You may set up a local test using [Docker][docker] and [Docker
  Compose][compose] by running `./scripts/load-testing.sh`.

### Local Vagrant environment

> WARNING: this environment may not fully work.

A [Vagrantfile][vagrantfile] to run the application in a local virtual machine
with Vagrant.

* Requires [Vagrant][vagrant], [VirtualBox][virtualbox] and [Ansible][ansible].
* [Microk8s][microk8s] is installed on the virtual machine to run the
  application in a [Kubernetes][k8s] cluster. The Ansible roles that do this are
  in the [`k8s` directory](./k8s).
* Define the following hosts in your `/etc/hosts` file:

      192.168.50.4 boardr.vagrant
      192.168.50.4 locust.boardr.vagrant
      192.168.50.4 traefik.boardr.vagrant
* **Note:** the Kubernetes configuration in the [`k8s/config`
  directory](./k8s/config) must be manually loaded from inside the virtual
  machine using the `kubectl` command. The directory is available inside the
  virtual machine at `/vagrant/k8s/config`.

### Raspberry Pi cluster

An [Ansible][ansible] playbook to run the application in a distributed cluster
of [Raspberry Pi single-board computers][rpi].

* The Ansible playbook and roles are in the [`cluster` directory](./cluster).
* Requires [Ansible][ansible] and at least 4 Raspberry Pi computers.
* The cluster can be simulated in local virtual machines using
  [Vagrant][vagrant] and [VirtualBox][virtualbox]. Use Vagrant from the
  `cluster` directory.

  * Define the following hosts in your `/etc/hosts` file:

        192.168.50.5 boardr.cluster.vagrant
* Copy `cluster/inventory.vagrant.yml` to `cluster/inventory.yml` and use that
  inventory to deploy the application to your own cluster. The configuration
  assumes each Raspberry has a fixed IP address.

  * Define the following hosts in your `/etc/hosts` file (assuming `10.0.1.100`
    is the Raspberry Pi on which the reverse proxy is running):

        10.0.1.100 boardr.cluster



## Requirements

### Runtime

As described in [`.tool-versions`][./tool-versions]:

```
elixir 1.10.0-otp-22
elm 0.19.1
erlang 22.2.3
nodejs 12.14.1
```

Run `asdf install` with [asdf][asdf] to install everything.

> Tested on macOS 10.14 & 10.15.

### Database

* [PostgreSQL][postgresql] 12.x



## Development

### Backend

Create `server/config/env.exs` with the following contents:

```elixir
use Mix.Config

config :boardr, :options,
  client_id: "GOOGLE_CLIENT_ID",
  client_secret: "GOOGLE_CLIENT_SECRET"

config :boardr, Boardr.Auth,
  secret_key_base: "CHANGE_ME_TO_A_VERY_LONG_RANDOM_STRING"
```

Migrate the database:

```bash
mix ecto.migrate
```

> The application will attempt to connect to the `boardr` database through the
> PostgreSQL Unix socket by default. Set `$BOARDR_DATABASE_URL` or
> `$DATABASE_URL` if your setup is different (e.g.
> `ecto://boardr:changeme@localhost:5432/boardr`).

Run the server in development mode:

```bash
cd backend
mix phx.server
```

Open http://localhost:4000/api.

### Frontend

```bash
cd frontend
npm ci
npm start
```

Open http://localhost:8000.



## TODO

### Documentation

* There are working Dockerfiles in `server` which should be documented.
* Document commands to set up the other environments (production, docker, load
  testing, Vagrant, cluster).

### Roadmap

* Use WebSocket, because an HTTP API for a web game was a bad idea to begin with
  (duh).
* See if Locust can be coerced into testing a non-request-response-based
  WebSocket API, or find another load testing tool.
* Find more things that don't fit to shoehorn into this project.



[ansible]: https://www.ansible.com
[asdf]: https://asdf-vm.com
[compose]: https://docs.docker.com/compose/
[docker]: https://www.docker.com
[elixir]: https://elixir-lang.org
[elixir-umbrella]: https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-projects.html
[elm]: https://elm-lang.org
[hal]: http://stateless.co/hal_specification.html
[http-problem-details]: https://tools.ietf.org/html/rfc7807
[k8s]: https://kubernetes.io
[locust]: https://locust.io
[microk8s]: https://microk8s.io
[postgresql]: https://www.postgresql.org
[rpi]: https://www.raspberrypi.org
[vagrant]: https://www.vagrantup.com
[vagrantfile]: https://www.vagrantup.com/docs/vagrantfile/
[virtualbox]: https://www.virtualbox.org
