# Forgejo Helm Chart <!-- omit from toc -->

- [Introduction](#introduction)
- [Update and versioning policy](#update-and-versioning-policy)
- [Dependencies](#dependencies)
  - [HA Dependencies](#ha-dependencies)
  - [Non-HA Dependencies](#non-ha-dependencies)
  - [Dependency Versioning](#dependency-versioning)
- [Installing](#installing)
- [High Availability](#high-availability)
- [Configuration](#configuration)
  - [Default Configuration](#default-configuration)
    - [Database defaults](#database-defaults)
    - [Server defaults](#server-defaults)
    - [Metrics defaults](#metrics-defaults)
    - [Rootless Defaults](#rootless-defaults)
    - [Session, Cache and Queue](#session-cache-and-queue)
  - [Single-Pod Configurations](#single-pod-configurations)
  - [Additional _app.ini_ settings](#additional-appini-settings)
    - [User defined environment variables in app.ini](#user-defined-environment-variables-in-appini)
  - [External Database](#external-database)
  - [Ports and external url](#ports-and-external-url)
  - [ClusterIP](#clusterip)
  - [SSH and Ingress](#ssh-and-ingress)
  - [SSH on crio based kubernetes cluster](#ssh-on-crio-based-kubernetes-cluster)
  - [Cache](#cache)
  - [Persistence](#persistence)
  - [Admin User](#admin-user)
  - [LDAP Settings](#ldap-settings)
  - [OAuth2 Settings](#oauth2-settings)
- [Configure commit signing](#configure-commit-signing)
- [Metrics and profiling](#metrics-and-profiling)
- [Pod annotations](#pod-annotations)
- [Themes](#themes)
- [Renovate](#renovate)
- [Parameters](#parameters)
  - [Global](#global)
  - [strategy](#strategy)
  - [Image](#image)
  - [Security](#security)
  - [Service](#service)
  - [Ingress](#ingress)
  - [deployment](#deployment)
  - [ServiceAccount](#serviceaccount)
  - [Persistence](#persistence-1)
  - [Init](#init)
  - [Signing](#signing)
  - [Gitea](#gitea)
  - [`app.ini` overrides](#appini-overrides)
  - [LivenessProbe](#livenessprobe)
  - [ReadinessProbe](#readinessprobe)
  - [StartupProbe](#startupprobe)
  - [Redis&reg; Cluster](#redis-cluster)
  - [Redis&reg;](#redis)
  - [PostgreSQL HA](#postgresql-ha)
  - [PostgreSQL](#postgresql)
  - [Advanced](#advanced)
- [Contributing](#contributing)
- [Upgrading](#upgrading)
  - [To v10](#to-v10)
  - [To v9](#to-v9)
  - [To v8](#to-v8)
  - [To v7](#to-v7)
  - [To v6](#to-v6)

[Forgejo](https://forgejo.org/) is a community managed lightweight code hosting solution written in Go.
It is published under the MIT license.

## Introduction

This Helm chart is based on the [Gitea chart](https://gitea.com/gitea/helm-chart).
Yet it takes a completely different approach in providing a database and cache with dependencies.
Additionally, this chart allows to provide LDAP and admin user configuration with values.

## Update and versioning policy

The Forgejo helm chart versioning does not follow Forgejo's versioning.
The latest chart version can be looked up in <https://code.forgejo.org/forgejo-helm/-/packages/container/forgejo> or in the [repository releases](https://code.forgejo.org/forgejo-helm/forgejo-helm/releases).

The chart aims to follow Forgejo's releases closely.
There might be times when the chart is behind the latest Forgejo release.
This might be caused by different reasons, most often due to time constraints of the maintainers (remember, all work here is done voluntarily in the spare time of people).
If you're eager to use the latest Forgejo version earlier than this chart catches up, then change the tag in `values.yaml` to the latest Forgejo version.
This is due to Forgejo not strictly following [semantic versioning](https://semver.org/#summary) as breaking changes do not increase the major version.
I.e., "minor" version bumps are considered "major".
Yet most often no issues will be encountered and the chart maintainers aim to communicate early/upfront if this would be the case.

## Dependencies

Forgejo can be run with an external database and cache.
This chart provides those dependencies, which can be enabled, or disabled via configuration.

### HA Dependencies

These dependencies are enabled by default:

- PostgreSQL HA ([Bitnami PostgreSQL-HA](https://github.com/bitnami/charts/blob/main/bitnami/postgresql-ha/Chart.yaml))
- Redis-Cluster ([Bitnami Redis-Cluster](https://github.com/bitnami/charts/blob/main/bitnami/redis-cluster/Chart.yaml))

### Non-HA Dependencies

Alternatively, the following non-HA replacements are available:

- PostgreSQL ([Bitnami PostgreSQL](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/Chart.yaml))
- Redis ([Bitnami Redis](https://github.com/bitnami/charts/blob/main/bitnami/redis/Chart.yaml))

### Dependency Versioning

Updates of sub-charts will be incorporated into the Gitea chart as they are released.
The reasoning behind this is that new users of the chart will start with the most recent sub-chart dependency versions.

**Note** If you want to stay on an older appVersion of a sub-chart dependency (e.g. PostgreSQL), you need to override the image tag in your `values.yaml` file.
In fact, we recommend to do so right from the start to be independent of major sub-chart dependency changes as they are released.
There is no need to update to every new PostgreSQL major version - you can happily skip some and do larger updates when you are ready for them.

We recommend to use a rolling tag like `:<majorVersion>-debian-<debian major version>` to incorporate minor and patch updates for the respective major version as they are released.
Alternatively you can also use a versioning helper tool like [renovate](https://github.com/renovatebot/renovate).

Please double-check the image repository and available tags in the sub-chart:

- [PostgreSQL-HA](https://hub.docker.com/r/bitnami/postgresql-repmgr/tags)
- [PostgreSQL](https://hub.docker.com/r/bitnami/postgresql/tags)
- [Redis Cluster](https://hub.docker.com/r/bitnami/redis-cluster/tags)
- [Redis](https://hub.docker.com/r/bitnami/redis/tags)

and look up the image tag which fits your needs on Dockerhub.

## Installing

```sh
helm install forgejo oci://code.forgejo.org/forgejo-helm/forgejo
```

In case you want to supply values, you can reference a `values.yaml` file:

```sh
helm install forgejo -f values.yaml oci://code.forgejo.org/forgejo-helm/forgejo
```

When upgrading, please refer to the [Upgrading](#upgrading) section at the bottom of this document for major and breaking changes.

## High Availability

This chart supports running Forgejo and it's dependencies in HA mode.
Care must be taken for production use as not all implementation details of Forgejo core are officially HA-ready yet.

Deploying a HA-ready Forgejo instance requires some effort including using HA-ready dependencies.
See the [HA Setup](docs/ha-setup.md) document for more details.

## Configuration

Forgejo offers lots of configuration options.
Every value described in the [Cheat Sheet](https://forgejo.org/docs/latest/admin/config-cheat-sheet/) can be set as a Helm value.
Configuration sections map to (lowercased) YAML blocks, while the keys themselves remain in all caps.

```yaml
gitea:
  config:
    # values in the DEFAULT section
    # (https://forgejo.org/docs/latest/admin/config-cheat-sheet/#overall-default)
    # are un-namespaced
    #
    APP_NAME: 'Forgejo: Git with a cup of tea'
    #
    # https://forgejo.org/docs/latest/admin/config-cheat-sheet/#repository-repository
    repository:
      ROOT: '~/gitea-repositories'
    #
    # https://forgejo.org/docs/latest/admin/config-cheat-sheet/#repository---pull-request-repositorypull-request
    repository.pull-request:
      WORK_IN_PROGRESS_PREFIXES: 'WIP:,[WIP]:'
```

### Default Configuration

This chart will set a few defaults in the Forgejo configuration based on the service and ingress settings.
All defaults can be overwritten in `gitea.config`.

INSTALL_LOCK is always set to true, since we want to configure Forgejo with this helm chart and everything is taken care of.

_All default settings are made directly in the generated `app.ini`, not in the Values._

#### Database defaults

If a builtIn database is enabled the database configuration is set automatically.
For example, PostgreSQL builtIn will appear in the `app.ini` as:

```ini
[database]
DB_TYPE = postgres
HOST = RELEASE-NAME-postgresql.default.svc.cluster.local:5432
NAME = gitea
PASSWD = gitea
USER = gitea
```

#### Server defaults

The server defaults are a bit more complex.
If ingress is `enabled`, the `ROOT_URL`, `DOMAIN` and `SSH_DOMAIN` will be set accordingly.
`HTTP_PORT` always defaults to `3000` as well as `SSH_PORT` to `22`.

```ini
[server]
APP_DATA_PATH = /data
DOMAIN = git.example.com
HTTP_PORT = 3000
PROTOCOL = http
ROOT_URL = http://git.example.com
SSH_DOMAIN = git.example.com
SSH_LISTEN_PORT = 22
SSH_PORT = 22
ENABLE_PPROF = false
```

#### Metrics defaults

The Prometheus `/metrics` endpoint is disabled by default.

```ini
[metrics]
ENABLED = false
```

#### Rootless Defaults

If `.Values.image.rootless: true`, then the following will occur. In case you use `.Values.image.fullOverride`, check that this works in your image:

- `$HOME` becomes `/data/gitea/git`

  [see deployment.yaml](./templates/gitea/deployment.yaml) template inside (init-)container "env" declarations

- `START_SSH_SERVER: true` (Unless explicity overwritten by `gitea.config.server.START_SSH_SERVER`)

  [see \_helpers.tpl](./templates/_helpers.tpl) in `gitea.inline_configuration.defaults.server` definition

- `SSH_LISTEN_PORT: 2222` (Unless explicity overwritten by `gitea.config.server.SSH_LISTEN_PORT`)

  [see \_helpers.tpl](./templates/_helpers.tpl) in `gitea.inline_configuration.defaults.server` definition

- `SSH_LOG_LEVEL` environment variable is not injected into the container

  [see deployment.yaml](./templates/gitea/deployment.yaml) template inside container "env" declarations

#### Session, Cache and Queue

The session, cache and queue settings are set to use the built-in Redis Cluster sub-chart dependency.
If Redis Cluster is disabled, the chart will fall back to the Gitea defaults which use "memory" for `session` and `cache` and "level" for `queue`.

While these will work and even not cause immediate issues after startup, **they are not recommended for production use**.
Reasons being that a single pod will take on all the work for `session` and `cache` tasks in its available memory.
It is likely that the pod will run out of memory or will face substantial memory spikes, depending on the workload.
External tools such as `redis-cluster` or `memcached` handle these workloads much better.

### Single-Pod Configurations

If HA is not needed/desired, the following configurations can be used to deploy a single-pod Forgejo instance.

1. For a production-ready single-pod Forgejo instance without external dependencies (using the chart dependency `postgresql` and `redis`):

   <details>

   <summary>values.yml</summary>

   ```yaml
   redis-cluster:
     enabled: false
   redis:
     enabled: true
   postgresql:
     enabled: true
   postgresql-ha:
     enabled: false

   persistence:
     enabled: true

   gitea:
     config:
       database:
         DB_TYPE: postgres
       indexer:
         ISSUE_INDEXER_TYPE: bleve
         REPO_INDEXER_ENABLED: true
   ```

   </details>

2. For a minimal DEV installation (using the built-in sqlite DB instead of Postgres):

   This will result in a single-pod Forgejo instance _without any dependencies and persistence_.
   **Do not use this configuration for production use**.

   <details>

   <summary>values.yml</summary>

   ```yaml
   redis-cluster:
     enabled: false
   redis:
     enabled: false
   postgresql:
     enabled: false
   postgresql-ha:
     enabled: false

   persistence:
     enabled: false

   gitea:
     config:
       database:
         DB_TYPE: sqlite3
       session:
         PROVIDER: memory
       cache:
         ADAPTER: memory
       queue:
         TYPE: level
   ```

   </details>

### Additional _app.ini_ settings

> **The [generic](https://forgejo.org/docs/latest/admin/config-cheat-sheet/#overall-default)
> section cannot be defined that way.**

Some settings inside _app.ini_ (like passwords or whole authentication configurations) must be considered sensitive and therefore should not be passed via plain text inside the _values.yaml_ file.
In times of _GitOps_ the values.yaml could be stored in a Git repository where sensitive data should never be accessible.

The Helm Chart supports this approach and let the user define custom sources like
Kubernetes Secrets to be loaded as environment variables during _app.ini_ creation or update.

```yaml
gitea:
  additionalConfigSources:
    - secret:
        secretName: gitea-app-ini-oauth
    - configMap:
        name: gitea-app-ini-plaintext
```

This would mount the two additional volumes (`oauth` and `some-additionals`) from different sources to the init container where the _app.ini_ gets updated.
All files mounted that way will be read and converted to environment variables and then added to the _app.ini_ using [environment-to-ini](https://github.com/go-gitea/gitea/tree/main/contrib/environment-to-ini).

The key of such additional source represents the section inside the _app.ini_.
The value for each key can be multiline ini-like definitions.

In example, the referenced `gitea-app-ini-plaintext` could look like this.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gitea-app-ini-plaintext
data:
  session: |
    PROVIDER=memory
    SAME_SITE=strict
  cron.archive_cleanup: |
    ENABLED=true
```

Or when using a Kubernetes secret, having the same data structure:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitea-security-related-configuration
type: Opaque
stringData:
  security: |
    PASSWORD_COMPLEXITY=off
  session: |
    SAME_SITE=strict
```

#### User defined environment variables in app.ini

Users are able to define their own environment variables, which are loaded into the containers.
We also support interacting directly with the generated _app.ini_.

To inject self defined variables into the _app.ini_ a certain format needs to be honored.
This is described in detail on the [env-to-ini](https://github.com/go-gitea/gitea/tree/main/contrib/environment-to-ini) page.

Environment variables need to be prefixed with `FORGEJO`.

For example a database setting needs to have the following format:

```yaml
gitea:
  config:
    database:
      HOST: my.own.host
  additionalConfigFromEnvs:
    - name: FORGEJO__DATABASE__PASSWD
      valueFrom:
        secretKeyRef:
          name: postgres-secret
          key: password
```

Priority (highest to lowest) for defining app.ini variables:

1. Environment variables prefixed with `FORGEJO`

1. Additional config sources
1. Values defined in `gitea.config`

### External Database

A [supported external database](https://forgejo.org/docs/latest/admin/config-cheat-sheet/#database-database/)can be used instead of the built-in PostgreSQL.
In fact, it is **highly recommended** to use an external database to ensure a stable Forgejo installation longterm.

If an external database is used, no matter which type, make sure to set `postgresql.enabled` to `false` to disable the use of the built-in PostgreSQL.

```yaml
gitea:
  config:
    database:
      DB_TYPE: mysql # supported values are mysql, postgres, mssql, sqlite3
      HOST: <mysql HOST>
      NAME: gitea
      USER: root
      PASSWD: gitea
      SCHEMA: gitea

postgresql:
  enabled: false
```

### Ports and external url

By default port `3000` is used for web traffic and `22` for ssh.
Those can be changed:

```yaml
service:
  http:
    port: 3000
  ssh:
    port: 22
```

This helm chart automatically configures the clone urls to use the correct ports.
You can change these ports by hand using the `gitea.config` dict.
However you should know what you're doing.

### ClusterIP

By default the `clusterIP` will be set to `None`, which is the default for headless services.
However if you want to omit the clusterIP field in the service, use the following values:

```yaml
service:
  http:
    type: ClusterIP
    port: 3000
    clusterIP:
  ssh:
    type: ClusterIP
    port: 22
    clusterIP:
```

### SSH and Ingress

If you're using ingress and want to use SSH, keep in mind, that ingress is not able to forward SSH Ports.
You will need a LoadBalancer like `metallb` and a setting in your ssh service annotations.

```yaml
service:
  ssh:
    annotations:
      metallb.universe.tf/allow-shared-ip: test
```

### SSH on crio based kubernetes cluster

If you use `crio` as container runtime it is not possible to read from a remote repository.
You should get an error message like this:

```bash
$ git clone git@k8s-demo.internal:admin/test.git
Cloning into 'test'...
Connection reset by 192.168.179.217 port 22
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

To solve this problem add the capability `SYS_CHROOT` to the `securityContext`.
More about this issue [here](https://gitea.com/gitea/helm-chart/issues/161).

### Cache

The cache handling is done via `redis-cluster` (via the `bitnami` chart) by default.
This deployment is HA-ready but can also be used for single-pod deployments.
By default, 6 replicas are deployed for a working `redis-cluster` deployment.
Many cloud providers offer a managed redis service, which can be used instead of the built-in `redis-cluster`.

```yaml
redis-cluster:
  enabled: true
```

### Persistence

Forgejo will be deployed as a deployment.
By simply enabling the persistence and setting the storage class according to your cluster everything else will be taken care of.
The following example will create a PVC as a part of the deployment.

Please note, that an empty `storageClass` in the persistence will result in kubernetes using your default storage class.

If you want to use your own storage class define it as follows:

```yaml
persistence:
  enabled: true
  storageClass: myOwnStorageClass
```

If you want to manage your own PVC you can simply pass the PVC name to the chart.

```yaml
persistence:
  enabled: true
  claimName: MyAwesomeGiteaClaim
```

In case that persistence has been disabled it will simply use an empty dir volume.

PostgreSQL handles the persistence in the exact same way.
You can interact with the postgres settings as displayed in the following example:

```yaml
postgresql:
  persistence:
    enabled: true
    claimName: MyAwesomeGiteaPostgresClaim
```

### Admin User

This chart enables you to create a default admin user.
It is also possible to update the password for this user by upgrading or redeploying the chart.
It is not possible to delete an admin user after it has been created.
This has to be done in the ui.
You cannot use `admin` as username.

```yaml
gitea:
  admin:
    username: 'MyAwesomeForgejoAdmin'
    password: 'AReallyAwesomeForgejoPassword'
    email: 'forge@jo.com'
```

You can also use an existing Secret to configure the admin user:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitea-admin-secret
type: Opaque
stringData:
  username: MyAwesomeGiteaAdmin
  password: AReallyAwesomeGiteaPassword
```

```yaml
gitea:
  admin:
    existingSecret: gitea-admin-secret
```

Whether you use the existing Secret or specify a user name and password, there are three modes for how the admin user password is created or set.

- `keepUpdated` (the default) will set the admin user password, and reset it to the defined value every time the pod is recreated.
- `initialOnlyNoReset` will set the admin user password when creating it, but never try to update the password.
- `initialOnlyRequireReset` will set the admin user password when creating it, never update it, and require that the password be changed at the initial login.

These modes can be set like the following:

```yaml
gitea:
  admin:
    passwordMode: initialOnlyRequireReset
```

### LDAP Settings

Like the admin user the LDAP settings can be updated.
All LDAP values from <https://forgejo.org/docs/latest/admin/command-line/#admin> are available.

Multiple LDAP sources can be configured with additional LDAP list items.

```yaml
gitea:
  ldap:
    - name: MyAwesomeGiteaLdap
      securityProtocol: unencrypted
      host: '127.0.0.1'
      port: '389'
      userSearchBase: ou=Users,dc=example,dc=com
      userFilter: sAMAccountName=%s
      adminFilter: CN=Admin,CN=Group,DC=example,DC=com
      emailAttribute: mail
      bindDn: CN=ldap read,OU=Spezial,DC=example,DC=com
      bindPassword: JustAnotherBindPw
      usernameAttribute: CN
      publicSSHKeyAttribute: publicSSHKey
```

You can also use an existing secret to set the `bindDn` and `bindPassword`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitea-ldap-secret
type: Opaque
stringData:
  bindDn: CN=ldap read,OU=Spezial,DC=example,DC=com
  bindPassword: JustAnotherBindPw
```

```yaml
gitea:
  ldap:
    - existingSecret: gitea-ldap-secret
```

⚠️ Some options are just flags and therefore don't have any values.
If they are defined in `gitea.ldap` configuration, they will be passed to the Forgejo CLI without any value.
Affected options:

- notActive
- skipTlsVerify
- allowDeactivateAll
- synchronizeUsers
- attributesInBind

### OAuth2 Settings

Like the admin user, OAuth2 settings can be updated and disabled but not deleted.
Deleting OAuth2 settings has to be done in the UI.
All OAuth2 values, which are documented [here](https://forgejo.org/docs/latest/admin/command-line/#admin), are available.

Multiple OAuth2 sources can be configured with additional OAuth list items.

```yaml
gitea:
  oauth:
    - name: 'MyAwesomeGiteaOAuth'
      provider: 'openidConnect'
      key: 'hello'
      secret: 'world'
      autoDiscoverUrl: 'https://gitea.example.com/.well-known/openid-configuration'
      #useCustomUrls:
      #customAuthUrl:
      #customTokenUrl:
      #customProfileUrl:
      #customEmailUrl:
```

You can also use an existing secret to set the `key` and `secret`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitea-oauth-secret
type: Opaque
stringData:
  key: hello
  secret: world
```

```yaml
gitea:
  oauth:
    - name: 'MyAwesomeGiteaOAuth'
      existingSecret: gitea-oauth-secret
```

### Compatibility with OCP (OKD or OpenShift)

Normally OCP is automatically detected and the compatibility mode set accordingly. To enforce the OCP compatibility mode use the following configuration:

```yaml
global:
  compatibility:
    openshift:
      adaptSecurityContext: force
```

An OCP route to access Forgejo can be enabled with the following config:

```yaml
route:
  enabled: true
```

## Configure commit signing

When using the rootless image the gpg key folder is not persistent by default.
If you consider using signed commits for internal Forgejo activities (e.g. initial commit), you'd need to provide a signing key.
Prior to [PR186](https://gitea.com/gitea/helm-chart/pulls/186), imported keys had to be re-imported once the container got replaced by another.

The mentioned PR introduced a new configuration object `signing` allowing you to configure prerequisites for commit signing.
By default this section is disabled to maintain backwards compatibility.

```yaml
signing:
  enabled: false
  gpgHome: /data/git/.gnupg
```

Regardless of the used container image the `signing` object allows to specify a private gpg key.
Either using the `signing.privateKey` to define the key inline, or refer to an existing secret containing the key data by using `signing.existingSecret`.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: custom-gitea-gpg-key
type: Opaque
stringData:
  privateKey: |-
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    ...
    -----END PGP PRIVATE KEY BLOCK-----
```

```yaml
signing:
  existingSecret: custom-gitea-gpg-key
```

To use the gpg key, Forgejo needs to be configured accordingly.
A detailed description can be found in the [documentation](https://forgejo.org/docs/latest/admin/signing/#general-configuration).

## Metrics and profiling

A Prometheus `/metrics` endpoint on the `HTTP_PORT` and `pprof` profiling endpoints on port 6060 can be enabled under `gitea`.
Beware that the metrics endpoint is exposed via the ingress, manage access using ingress annotations for example.

To deploy the `ServiceMonitor`, you first need to ensure that you have deployed `prometheus-operator` and its [CRDs](https://github.com/prometheus-operator/prometheus-operator#customresourcedefinitions).

```yaml
gitea:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true

  config:
    server:
      ENABLE_PPROF: true
```

## Pod annotations

Annotations can be added to the Forgejo pod.

```yaml
gitea:
  podAnnotations: {}
```

## Themes

Custom themes can be added via k8s secrets and referencing them in `values.yaml`.

The [http provider](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) is useful here.

```yaml
extraVolumes:
  - name: gitea-themes
    secret:
      secretName: gitea-themes

extraVolumeMounts:
  - name: gitea-themes
    readOnly: true
    mountPath: '/data/gitea/public/assets/css'
```

The secret can be created via `terraform`:

```hcl
resource "kubernetes_secret" "gitea-themes" {
  metadata {
    name      = "gitea-themes"
    namespace = "gitea"
  }

  data = {
    "my-theme.css"      = data.http.gitea-theme-light.body
    "my-theme-dark.css" = data.http.gitea-theme-dark.body
    "my-theme-auto.css" = data.http.gitea-theme-auto.body
  }

  type = "Opaque"
}


data "http" "gitea-theme-light" {
  url = "<raw theme url>"

  request_headers = {
    Accept = "application/json"
  }
}

data "http" "gitea-theme-dark" {
  url = "<raw theme url>"

  request_headers = {
    Accept = "application/json"
  }
}

data "http" "gitea-theme-auto" {
  url = "<raw theme url>"

  request_headers = {
    Accept = "application/json"
  }
}
```

or natively via `kubectl`:

```bash
kubectl create secret generic gitea-themes --from-file={{FULL-PATH-TO-CSS}} --namespace gitea
```

## Renovate

To be able to use a digest value which is automatically updated by `Renovate` a [customManager](https://docs.renovatebot.com/modules/manager/regex/) is required.
Here's an examplary `values.yml` definition which makes use of a digest:

```yaml
image:
  registry: code.forgejo.org
  repository: forgejo/forgejo
  tag: 1.20.2-0
  digest: sha256:f597c14a403c2fdee9a62dae8bae29d6442f7b2cc85872cc9bb535a24cb1630e
```

By default Renovate adds digest after the `tag`.
To comply with the Forgejo helm chart definition of the digest parameter, a "customManagers" definition is required:

```json
"customManagers": [
  {
    "customType": "regex",
    "description": "Apply an explicit gitea digest field match",
    "fileMatch": ["values\\.ya?ml"],
    "matchStrings": ["(?<depName>forgejo\\/forgejo)\\n(?<indentation>\\s+)tag: (?<currentValue>[^@].*?)\\n\\s+digest: (?<currentDigest>sha256:[a-f0-9]+)"],
    "datasourceTemplate": "docker",
    "packageNameTemplate": "code.forgejo.org/{{depName}}",
    "autoReplaceStringTemplate": "{{depName}}\n{{indentation}}tag: {{newValue}}\n{{indentation}}digest: {{#if newDigest}}{{{newDigest}}}{{else}}{{{currentDigest}}}{{/if}}"
  }
]
```

## Parameters

### Global

| Name                      | Description                                                               | Value |
| ------------------------- | ------------------------------------------------------------------------- | ----- |
| `global.imageRegistry`    | global image registry override                                            | `""`  |
| `global.imagePullSecrets` | global image pull secrets override; can be extended by `imagePullSecrets` | `[]`  |
| `global.storageClass`     | global storage class override                                             | `""`  |
| `global.hostAliases`      | global hostAliases which will be added to the pod's hosts files           | `[]`  |
| `namespaceOverride`       | String to fully override common.names.namespace                           | `""`  |
| `replicaCount`            | number of replicas for the deployment                                     | `1`   |

### strategy

| Name                                    | Description    | Value           |
| --------------------------------------- | -------------- | --------------- |
| `strategy.type`                         | strategy type  | `RollingUpdate` |
| `strategy.rollingUpdate.maxSurge`       | maxSurge       | `100%`          |
| `strategy.rollingUpdate.maxUnavailable` | maxUnavailable | `0`             |
| `clusterDomain`                         | cluster domain | `cluster.local` |

### Image

| Name                 | Description                                                                                                                                                      | Value              |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `image.registry`     | image registry, e.g. gcr.io,docker.io                                                                                                                            | `code.forgejo.org` |
| `image.repository`   | Image to start for this pod                                                                                                                                      | `forgejo/forgejo`  |
| `image.tag`          | Visit: [Image tag](https://code.forgejo.org/forgejo/-/packages/container/forgejo/versions). Defaults to `appVersion` within Chart.yaml.                          | `""`               |
| `image.digest`       | Image digest. Allows to pin the given image tag. Useful for having control over mutable tags like `latest`                                                       | `""`               |
| `image.pullPolicy`   | Image pull policy                                                                                                                                                | `IfNotPresent`     |
| `image.rootless`     | Wether or not to pull the rootless version of Forgejo                                                                                                            | `true`             |
| `image.fullOverride` | Completely overrides the image registry, path/image, tag and digest. **Adjust `image.rootless` accordingly and review [Rootless defaults](#rootless-defaults).** | `""`               |
| `imagePullSecrets`   | Secret to use for pulling the image                                                                                                                              | `[]`               |

### Security

| Name                         | Description                                                     | Value  |
| ---------------------------- | --------------------------------------------------------------- | ------ |
| `podSecurityContext.fsGroup` | Set the shared file system group for all containers in the pod. | `1000` |
| `containerSecurityContext`   | Security context                                                | `{}`   |
| `securityContext`            | Run init and Forgejo containers as a specific securityContext   | `{}`   |
| `podDisruptionBudget`        | Pod disruption budget                                           | `{}`   |

### Service

| Name                                    | Description                                                                                                                                                                                          | Value       |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `service.http.type`                     | Kubernetes service type for web traffic                                                                                                                                                              | `ClusterIP` |
| `service.http.port`                     | Port number for web traffic                                                                                                                                                                          | `3000`      |
| `service.http.clusterIP`                | ClusterIP setting for http autosetup for deployment is None                                                                                                                                          | `None`      |
| `service.http.loadBalancerIP`           | LoadBalancer IP setting                                                                                                                                                                              | `nil`       |
| `service.http.nodePort`                 | NodePort for http service                                                                                                                                                                            | `nil`       |
| `service.http.externalTrafficPolicy`    | If `service.http.type` is `NodePort` or `LoadBalancer`, set this to `Local` to enable source IP preservation                                                                                         | `nil`       |
| `service.http.externalIPs`              | External IPs for service                                                                                                                                                                             | `nil`       |
| `service.http.ipFamilyPolicy`           | HTTP service dual-stack policy                                                                                                                                                                       | `nil`       |
| `service.http.ipFamilies`               | HTTP service dual-stack familiy selection,for dual-stack parameters see official kubernetes [dual-stack concept documentation](https://kubernetes.io/docs/concepts/services-networking/dual-stack/). | `nil`       |
| `service.http.loadBalancerSourceRanges` | Source range filter for http loadbalancer                                                                                                                                                            | `[]`        |
| `service.http.annotations`              | HTTP service annotations                                                                                                                                                                             | `{}`        |
| `service.http.labels`                   | HTTP service additional labels                                                                                                                                                                       | `{}`        |
| `service.http.loadBalancerClass`        | Loadbalancer class                                                                                                                                                                                   | `nil`       |
| `service.ssh.type`                      | Kubernetes service type for ssh traffic                                                                                                                                                              | `ClusterIP` |
| `service.ssh.port`                      | Port number for ssh traffic                                                                                                                                                                          | `22`        |
| `service.ssh.clusterIP`                 | ClusterIP setting for ssh autosetup for deployment is None                                                                                                                                           | `None`      |
| `service.ssh.loadBalancerIP`            | LoadBalancer IP setting                                                                                                                                                                              | `nil`       |
| `service.ssh.nodePort`                  | NodePort for ssh service                                                                                                                                                                             | `nil`       |
| `service.ssh.externalTrafficPolicy`     | If `service.ssh.type` is `NodePort` or `LoadBalancer`, set this to `Local` to enable source IP preservation                                                                                          | `nil`       |
| `service.ssh.externalIPs`               | External IPs for service                                                                                                                                                                             | `nil`       |
| `service.ssh.ipFamilyPolicy`            | SSH service dual-stack policy                                                                                                                                                                        | `nil`       |
| `service.ssh.ipFamilies`                | SSH service dual-stack familiy selection,for dual-stack parameters see official kubernetes [dual-stack concept documentation](https://kubernetes.io/docs/concepts/services-networking/dual-stack/).  | `nil`       |
| `service.ssh.hostPort`                  | HostPort for ssh service                                                                                                                                                                             | `nil`       |
| `service.ssh.loadBalancerSourceRanges`  | Source range filter for ssh loadbalancer                                                                                                                                                             | `[]`        |
| `service.ssh.annotations`               | SSH service annotations                                                                                                                                                                              | `{}`        |
| `service.ssh.labels`                    | SSH service additional labels                                                                                                                                                                        | `{}`        |
| `service.ssh.loadBalancerClass`         | Loadbalancer class                                                                                                                                                                                   | `nil`       |

### Ingress

| Name                                 | Description                                                                 | Value             |
| ------------------------------------ | --------------------------------------------------------------------------- | ----------------- |
| `ingress.enabled`                    | Enable ingress                                                              | `false`           |
| `ingress.className`                  | Ingress class name                                                          | `nil`             |
| `ingress.annotations`                | Ingress annotations                                                         | `{}`              |
| `ingress.hosts[0].host`              | Default Ingress host                                                        | `git.example.com` |
| `ingress.hosts[0].paths[0].path`     | Default Ingress path                                                        | `/`               |
| `ingress.hosts[0].paths[0].pathType` | Ingress path type                                                           | `Prefix`          |
| `ingress.tls`                        | Ingress tls settings                                                        | `[]`              |
| `ingress.apiVersion`                 | Specify APIVersion of ingress object. Mostly would only be used for argocd. |                   |

### Route

| Name                                      | Description                                                                                                                                                                                       | Value      |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| `route.enabled`                           | Enable route                                                                                                                                                                                      | `false`    |
| `route.annotations`                       | Route annotations                                                                                                                                                                                 | `{}`       |
| `route.host`                              | Host to use for the route (will be assigned automatically by OKD / OpenShift is not defined)                                                                                                      | `nil`      |
| `route.wildcardPolicy`                    | Wildcard policy if any for the route, currently only 'Subdomain' or 'None' is allowed.                                                                                                            | `nil`      |
| `route.tls.termination`                   | termination type (see [OKD documentation](https://docs.okd.io/latest/rest_api/network_apis/route-route-openshift-io-v1.html#spec-tls))                                                            | `edge`     |
| `route.tls.insecureEdgeTerminationPolicy` | the desired behavior for insecure connections to a route (e.g. with http)                                                                                                                         | `Redirect` |
| `route.tls.existingSecret`                | the name of a predefined secret of type kubernetes.io/tls with both key (tls.crt and tls.key) set accordingly (if defined attributes 'certificate', 'caCertificate' and 'privateKey' are ignored) | `nil`      |
| `route.tls.certificate`                   | PEM encoded single certificate                                                                                                                                                                    | `nil`      |
| `route.tls.privateKey`                    | PEM encoded private key                                                                                                                                                                           | `nil`      |
| `route.tls.caCertificate`                 | PEM encoded CA certificate or chain that issued the certificate                                                                                                                                   | `nil`      |
| `route.tls.destinationCACertificate`      | PEM encoded CA certificate used to verify the authenticity of final end point when 'termination' is set to 'passthrough' (ignored otherwise)                                                      | `nil`      |

### deployment

| Name                                       | Description                                            | Value |
| ------------------------------------------ | ------------------------------------------------------ | ----- |
| `resources`                                | Kubernetes resources                                   | `{}`  |
| `schedulerName`                            | Use an alternate scheduler, e.g. "stork"               | `""`  |
| `nodeSelector`                             | NodeSelector for the deployment                        | `{}`  |
| `tolerations`                              | Tolerations for the deployment                         | `[]`  |
| `affinity`                                 | Affinity for the deployment                            | `{}`  |
| `topologySpreadConstraints`                | TopologySpreadConstraints for the deployment           | `[]`  |
| `dnsConfig`                                | dnsConfig for the deployment                           | `{}`  |
| `priorityClassName`                        | priorityClassName for the deployment                   | `""`  |
| `deployment.env`                           | Additional environment variables to pass to containers | `[]`  |
| `deployment.terminationGracePeriodSeconds` | How long to wait until forcefully kill the pod         | `60`  |
| `deployment.labels`                        | Labels for the deployment                              | `{}`  |
| `deployment.annotations`                   | Annotations for the Forgejo deployment to be created   | `{}`  |

### ServiceAccount

| Name                                          | Description                                                                                                                               | Value   |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`                       | Enable the creation of a ServiceAccount                                                                                                   | `false` |
| `serviceAccount.name`                         | Name of the created ServiceAccount, defaults to release name. Can also link to an externally provided ServiceAccount that should be used. | `""`    |
| `serviceAccount.automountServiceAccountToken` | Enable/disable auto mounting of the service account token                                                                                 | `false` |
| `serviceAccount.imagePullSecrets`             | Image pull secrets, available to the ServiceAccount                                                                                       | `[]`    |
| `serviceAccount.annotations`                  | Custom annotations for the ServiceAccount                                                                                                 | `{}`    |
| `serviceAccount.labels`                       | Custom labels for the ServiceAccount                                                                                                      | `{}`    |

### Persistence

| Name                                              | Description                                                                                             | Value                  |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ---------------------- |
| `persistence.enabled`                             | Enable persistent storage                                                                               | `true`                 |
| `persistence.create`                              | Whether to create the persistentVolumeClaim for shared storage                                          | `true`                 |
| `persistence.mount`                               | Whether the persistentVolumeClaim should be mounted (even if not created)                               | `true`                 |
| `persistence.claimName`                           | Use an existing claim to store repository information                                                   | `gitea-shared-storage` |
| `persistence.size`                                | Size for persistence to store repo information                                                          | `10Gi`                 |
| `persistence.accessModes`                         | AccessMode for persistence                                                                              | `["ReadWriteOnce"]`    |
| `persistence.labels`                              | Labels for the persistence volume claim to be created                                                   | `{}`                   |
| `persistence.annotations.helm.sh/resource-policy` | Resource policy for the persistence volume claim                                                        | `keep`                 |
| `persistence.storageClass`                        | Name of the storage class to use                                                                        | `nil`                  |
| `persistence.subPath`                             | Subdirectory of the volume to mount at                                                                  | `nil`                  |
| `persistence.volumeName`                          | Name of persistent volume in PVC                                                                        | `""`                   |
| `extraVolumes`                                    | Additional volumes to mount to the Forgejo deployment                                                   | `[]`                   |
| `extraContainerVolumeMounts`                      | Mounts that are only mapped into the Forgejo runtime/main container, to e.g. override custom templates. | `[]`                   |
| `extraInitVolumeMounts`                           | Mounts that are only mapped into the init-containers. Can be used for additional preconfiguration.      | `[]`                   |
| `extraVolumeMounts`                               | **DEPRECATED** Additional volume mounts for init containers and the Forgejo main container              | `[]`                   |

### Init

| Name                                       | Description                                                                          | Value   |
| ------------------------------------------ | ------------------------------------------------------------------------------------ | ------- |
| `initPreScript`                            | Bash shell script copied verbatim to the start of the init-container.                | `""`    |
| `initContainers.resources.limits`          | initContainers.limits Kubernetes resource limits for init containers                 | `{}`    |
| `initContainers.resources.requests.cpu`    | initContainers.requests.cpu Kubernetes cpu resource limits for init containers       | `100m`  |
| `initContainers.resources.requests.memory` | initContainers.requests.memory Kubernetes memory resource limits for init containers | `128Mi` |

### Signing

| Name                     | Description                                                       | Value              |
| ------------------------ | ----------------------------------------------------------------- | ------------------ |
| `signing.enabled`        | Enable commit/action signing                                      | `false`            |
| `signing.gpgHome`        | GPG home directory                                                | `/data/git/.gnupg` |
| `signing.privateKey`     | Inline private gpg key for signed internal Git activity           | `""`               |
| `signing.existingSecret` | Use an existing secret to store the value of `signing.privateKey` | `""`               |

### Gitea

| Name                                     | Description                                                                                                                   | Value                |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| `gitea.admin.username`                   | Username for the Forgejo admin user                                                                                           | `gitea_admin`        |
| `gitea.admin.existingSecret`             | Use an existing secret to store admin user credentials                                                                        | `nil`                |
| `gitea.admin.password`                   | Password for the Forgejo admin user                                                                                           | `r8sA8CPHD9!bt6d`    |
| `gitea.admin.email`                      | Email for the Forgejo admin user                                                                                              | `gitea@local.domain` |
| `gitea.admin.passwordMode`               | Mode for how to set/update the admin user password. Options are: initialOnlyNoReset, initialOnlyRequireReset, and keepUpdated | `keepUpdated`        |
| `gitea.metrics.enabled`                  | Enable Forgejo metrics                                                                                                        | `false`              |
| `gitea.metrics.serviceMonitor.enabled`   | Enable Forgejo metrics service monitor                                                                                        | `false`              |
| `gitea.metrics.serviceMonitor.namespace` | Namespace in which Prometheus is running                                                                                      | `""`                 |
| `gitea.ldap`                             | LDAP configuration                                                                                                            | `[]`                 |
| `gitea.oauth`                            | OAuth configuration                                                                                                           | `[]`                 |
| `gitea.additionalConfigSources`          | Additional configuration from secret or configmap                                                                             | `[]`                 |
| `gitea.additionalConfigFromEnvs`         | Additional configuration sources from environment variables                                                                   | `[]`                 |
| `gitea.podAnnotations`                   | Annotations for the Forgejo pod                                                                                               | `{}`                 |
| `gitea.ssh.logLevel`                     | Configure OpenSSH's log level. Only available for root-based Forgejo image.                                                   | `INFO`               |

### `app.ini` overrides

Every value described in the [Cheat
Sheet](https://forgejo.org/docs/latest/admin/config-cheat-sheet/) can be
set as a Helm value. Configuration sections map to (lowercased) YAML
blocks, while the keys themselves remain in all caps.

| Name                                 | Description                                                                                                                                    | Value                               |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| `gitea.config.APP_NAME`              | Application name, used in the page title                                                                                                       | `Forgejo: Beyond coding. We forge.` |
| `gitea.config.RUN_MODE`              | Application run mode, affects performance and debugging: `dev` or `prod`                                                                       | `prod`                              |
| `gitea.config.repository`            | General repository settings                                                                                                                    | `{}`                                |
| `gitea.config.cors`                  | Cross-origin resource sharing settings                                                                                                         | `{}`                                |
| `gitea.config.ui`                    | User interface settings                                                                                                                        | `{}`                                |
| `gitea.config.markdown`              | Markdown parser settings                                                                                                                       | `{}`                                |
| `gitea.config.server`                | General server settings                                                                                                                        | `{}`                                |
| `gitea.config.database`              | Database configuration (only necessary with an [externally managed DB](https://code.forgejo.org/forgejo-helm/forgejo-helm#external-database)). | `{}`                                |
| `gitea.config.indexer`               | Settings for what content is indexed and how                                                                                                   | `{}`                                |
| `gitea.config.queue`                 | Job queue configuration                                                                                                                        | `{}`                                |
| `gitea.config.admin`                 | Admin user settings                                                                                                                            | `{}`                                |
| `gitea.config.security`              | Site security settings                                                                                                                         | `{}`                                |
| `gitea.config.camo`                  | Settings for the [camo](https://github.com/cactus/go-camo) media proxy server (disabled by default)                                            | `{}`                                |
| `gitea.config.openid`                | Configuration for authentication with OpenID (disabled by default)                                                                             | `{}`                                |
| `gitea.config.oauth2_client`         | OAuth2 client settings                                                                                                                         | `{}`                                |
| `gitea.config.service`               | Configuration for miscellaneous Forgejo services                                                                                               | `{}`                                |
| `gitea.config.ssh.minimum_key_sizes` | SSH minimum key sizes                                                                                                                          | `{}`                                |
| `gitea.config.webhook`               | Webhook settings                                                                                                                               | `{}`                                |
| `gitea.config.mailer`                | Mailer configuration (disabled by default)                                                                                                     | `{}`                                |
| `gitea.config.email.incoming`        | Configuration for handling incoming mail (disabled by default)                                                                                 | `{}`                                |
| `gitea.config.cache`                 | Cache configuration                                                                                                                            | `{}`                                |
| `gitea.config.session`               | Session/cookie handling                                                                                                                        | `{}`                                |
| `gitea.config.picture`               | User avatar settings                                                                                                                           | `{}`                                |
| `gitea.config.project`               | Project board defaults                                                                                                                         | `{}`                                |
| `gitea.config.attachment`            | Issue and PR attachment configuration                                                                                                          | `{}`                                |
| `gitea.config.log`                   | Logging configuration                                                                                                                          | `{}`                                |
| `gitea.config.cron`                  | Cron job configuration                                                                                                                         | `{}`                                |
| `gitea.config.git`                   | Global settings for Git                                                                                                                        | `{}`                                |
| `gitea.config.metrics`               | Settings for the Prometheus endpoint (disabled by default)                                                                                     | `{}`                                |
| `gitea.config.api`                   | Settings for the Swagger API documentation endpoints                                                                                           | `{}`                                |
| `gitea.config.oauth2`                | Settings for the [OAuth2 provider](https://forgejo.org/docs/latest/admin/oauth2-provider/)                                                     | `{}`                                |
| `gitea.config.i18n`                  | Internationalization settings                                                                                                                  | `{}`                                |
| `gitea.config.markup`                | Configuration for advanced markup processors                                                                                                   | `{}`                                |
| `gitea.config.highlight.mapping`     | File extension to language mapping overrides for syntax highlighting                                                                           | `{}`                                |
| `gitea.config.time`                  | Locale settings                                                                                                                                | `{}`                                |
| `gitea.config.migrations`            | Settings for Git repository migrations                                                                                                         | `{}`                                |
| `gitea.config.federation`            | Federation configuration                                                                                                                       | `{}`                                |
| `gitea.config.packages`              | Package registry settings                                                                                                                      | `{}`                                |
| `gitea.config.mirror`                | Configuration for repository mirroring                                                                                                         | `{}`                                |
| `gitea.config.lfs`                   | Large File Storage configuration                                                                                                               | `{}`                                |
| `gitea.config.repo-avatar`           | Repository avatar storage configuration                                                                                                        | `{}`                                |
| `gitea.config.avatar`                | User/org avatar storage configuration                                                                                                          | `{}`                                |
| `gitea.config.storage`               | General storage settings                                                                                                                       | `{}`                                |
| `gitea.config.proxy`                 | Proxy configuration (disabled by default)                                                                                                      | `{}`                                |
| `gitea.config.actions`               | Configuration for [Forgejo Actions](https://forgejo.org/docs/latest/user/actions/)                                                             | `{}`                                |
| `gitea.config.other`                 | Uncategorized configuration options                                                                                                            | `{}`                                |

### LivenessProbe

| Name                                      | Description                                      | Value  |
| ----------------------------------------- | ------------------------------------------------ | ------ |
| `gitea.livenessProbe.enabled`             | Enable liveness probe                            | `true` |
| `gitea.livenessProbe.tcpSocket.port`      | Port to probe for liveness                       | `http` |
| `gitea.livenessProbe.initialDelaySeconds` | Initial delay before liveness probe is initiated | `200`  |
| `gitea.livenessProbe.timeoutSeconds`      | Timeout for liveness probe                       | `1`    |
| `gitea.livenessProbe.periodSeconds`       | Period for liveness probe                        | `10`   |
| `gitea.livenessProbe.successThreshold`    | Success threshold for liveness probe             | `1`    |
| `gitea.livenessProbe.failureThreshold`    | Failure threshold for liveness probe             | `10`   |

### ReadinessProbe

| Name                                       | Description                                       | Value  |
| ------------------------------------------ | ------------------------------------------------- | ------ |
| `gitea.readinessProbe.enabled`             | Enable readiness probe                            | `true` |
| `gitea.readinessProbe.tcpSocket.port`      | Port to probe for readiness                       | `http` |
| `gitea.readinessProbe.initialDelaySeconds` | Initial delay before readiness probe is initiated | `5`    |
| `gitea.readinessProbe.timeoutSeconds`      | Timeout for readiness probe                       | `1`    |
| `gitea.readinessProbe.periodSeconds`       | Period for readiness probe                        | `10`   |
| `gitea.readinessProbe.successThreshold`    | Success threshold for readiness probe             | `1`    |
| `gitea.readinessProbe.failureThreshold`    | Failure threshold for readiness probe             | `3`    |

### StartupProbe

| Name                                     | Description                                     | Value   |
| ---------------------------------------- | ----------------------------------------------- | ------- |
| `gitea.startupProbe.enabled`             | Enable startup probe                            | `false` |
| `gitea.startupProbe.tcpSocket.port`      | Port to probe for startup                       | `http`  |
| `gitea.startupProbe.initialDelaySeconds` | Initial delay before startup probe is initiated | `60`    |
| `gitea.startupProbe.timeoutSeconds`      | Timeout for startup probe                       | `1`     |
| `gitea.startupProbe.periodSeconds`       | Period for startup probe                        | `10`    |
| `gitea.startupProbe.successThreshold`    | Success threshold for startup probe             | `1`     |
| `gitea.startupProbe.failureThreshold`    | Failure threshold for startup probe             | `10`    |

### Redis&reg; Cluster

Redis&reg; Cluster is loaded as a dependency from [Bitnami](https://github.com/bitnami/charts/tree/master/bitnami/redis-cluster) if enabled in the values.
Complete Configuration can be taken from their website.
Redis cluster and [Redis](#redis) cannot be enabled at the same time.

| Name                             | Description                                  | Value   |
| -------------------------------- | -------------------------------------------- | ------- |
| `redis-cluster.enabled`          | Enable redis cluster                         | `true`  |
| `redis-cluster.usePassword`      | Whether to use password authentication       | `false` |
| `redis-cluster.cluster.nodes`    | Number of redis cluster master nodes         | `3`     |
| `redis-cluster.cluster.replicas` | Number of redis cluster master node replicas | `0`     |

### Redis&reg;

Redis&reg; is loaded as a dependency from [Bitnami](https://github.com/bitnami/charts/tree/master/bitnami/redis) if enabled in the values.
Complete Configuration can be taken from their website.
Redis and [Redis cluster](#redis-cluster) cannot be enabled at the same time.

| Name                          | Description                                | Value        |
| ----------------------------- | ------------------------------------------ | ------------ |
| `redis.enabled`               | Enable redis standalone or replicated      | `false`      |
| `redis.architecture`          | Whether to use standalone or replication   | `standalone` |
| `redis.global.redis.password` | Required password                          | `changeme`   |
| `redis.master.count`          | Number of Redis master instances to deploy | `1`          |

### PostgreSQL HA

PostgreSQL HA is loaded as a dependency from [Bitnami](https://github.com/bitnami/charts/tree/master/bitnami/postgresql-ha) if enabled in the values.
Complete Configuration can be taken from their website.

| Name                                        | Description                                                      | Value       |
| ------------------------------------------- | ---------------------------------------------------------------- | ----------- |
| `postgresql-ha.enabled`                     | Enable PostgreSQL HA chart                                       | `true`      |
| `postgresql-ha.postgresql.password`         | Password for the `gitea` user (overrides `auth.password`)        | `changeme4` |
| `postgresql-ha.global.postgresql.database`  | Name for a custom database to create (overrides `auth.database`) | `gitea`     |
| `postgresql-ha.global.postgresql.username`  | Name for a custom user to create (overrides `auth.username`)     | `gitea`     |
| `postgresql-ha.global.postgresql.password`  | Name for a custom password to create (overrides `auth.password`) | `gitea`     |
| `postgresql-ha.postgresql.repmgrPassword`   | Repmgr Password                                                  | `changeme2` |
| `postgresql-ha.postgresql.postgresPassword` | postgres Password                                                | `changeme1` |
| `postgresql-ha.pgpool.adminPassword`        | pgpool adminPassword                                             | `changeme3` |
| `postgresql-ha.service.ports.postgresql`    | PostgreSQL service port (overrides `service.ports.postgresql`)   | `5432`      |
| `postgresql-ha.primary.persistence.size`    | PVC Storage Request for PostgreSQL HA volume                     | `10Gi`      |

### PostgreSQL

PostgreSQL is loaded as a dependency from [Bitnami](https://github.com/bitnami/charts/tree/master/bitnami/postgresql) if enabled in the values.
Complete Configuration can be taken from their website.

| Name                                                    | Description                                                      | Value   |
| ------------------------------------------------------- | ---------------------------------------------------------------- | ------- |
| `postgresql.enabled`                                    | Enable PostgreSQL                                                | `false` |
| `postgresql.global.postgresql.auth.password`            | Password for the `gitea` user (overrides `auth.password`)        | `gitea` |
| `postgresql.global.postgresql.auth.database`            | Name for a custom database to create (overrides `auth.database`) | `gitea` |
| `postgresql.global.postgresql.auth.username`            | Name for a custom user to create (overrides `auth.username`)     | `gitea` |
| `postgresql.global.postgresql.service.ports.postgresql` | PostgreSQL service port (overrides `service.ports.postgresql`)   | `5432`  |
| `postgresql.primary.persistence.size`                   | PVC Storage Request for PostgreSQL volume                        | `10Gi`  |

### Advanced

| Name               | Description                                                        | Value     |
| ------------------ | ------------------------------------------------------------------ | --------- |
| `checkDeprecation` | Set it to false to skip this basic validation check.               | `true`    |
| `test.enabled`     | Set it to false to disable test-connection Pod.                    | `true`    |
| `test.image.name`  | Image name for the wget container used in the test-connection Pod. | `busybox` |
| `test.image.tag`   | Image tag for the wget container used in the test-connection Pod.  | `latest`  |
| `extraDeploy`      | Array of extra objects to deploy with the release                  | `[]`      |

## Contributing

Expected workflow is: Fork -> Patch -> Push -> Pull Request

See [CONTRIBUTORS GUIDE](CONTRIBUTING.md) for details.

Hop into [our Matrix room](https://matrix.to/#/#forgejo-helm-chart:matrix.org) if you have any questions or want to get involved.

## Upgrading

This section lists major and breaking changes of each Helm Chart version.
Please read them carefully to upgrade successfully, especially the change of the **default database backend**!
If you miss this, blindly upgrading may delete your Postgres instance and you may lose your data!

### To v10

You need Forgejo v9+ to use this Helm Chart version.
Forgejo v8 is now EOL.

### To v9

Namespaces for all resources are now set to `common.names.namespace` by default.

### To v8

You need Forgejo v8+ to use this Helm Chart version.
Use the v7 Helm Chart for Forgejo v7.

### To v7

The Forgejo docker image is pulled from `code.forgejo.org` instead of `codeberg.org`.

### To v6

You need Forgejo v7+ to use this Helm Chart version.
Use the v5 Helm Chart for Forgejo v1.21.
