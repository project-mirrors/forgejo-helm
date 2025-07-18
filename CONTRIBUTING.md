# Contribution Guidelines

Any type of contribution is welcome; from new features, bug fixes, tests,
refactorings for easier maintainability or documentation improvements.

## Development environment

- [`node`](https://nodejs.org/en/) at least current LTS
- [`helm`](https://helm.sh/docs/intro/install/)
- `make` is optional; you may call the commands directly

When using Visual Studio Code as IDE, a [ready-to-use profile](.vscode/) is available.

## Documentation Requirements

The `README.md` must include all configuration options.
The parameters section is generated by extracting the parameter annotations from the `values.yaml` file, by using [this tool](https://github.com/bitnami-labs/readme-generator-for-helm).

If changes were made on configuration options, run `make readme` to update the README file.

The ToC is created via the VSCode [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) extension which can/must also be used used to update it.

## Pull Request Requirements

When submitting or updating a PR:

- make sure it passes CI builds.
- do not make independent changes in one PR.
- try to avoid rebases. They make code reviews for large PRs and comments much harder.
- if applicable, use the PR template for a well-defined PR description.
- clearly mark breaking changes.

## Local development & testing

For local development and testing of pull requests, the following workflow can
be used:

1. Install `minikube` and `helm`.
1. Start a `minikube` cluster via `minikube start`.
1. From the `forgejo-contrib/forgejo-helm` directory execute the following command.
   This will install the dependencies listed in `Chart.yml` and deploy the current state of the helm chart found locally.
   If you want to test a branch, make sure to switch to the respective branch first.
   `helm install --dependency-update forgejo . -f values.yaml`.
1. Forgejo is now deployed in `minikube`.
   To access it, it's port needs to be forwarded first from `minikube` to localhost first via `kubectl --namespace
default port-forward svc/gitea-http 3000:3000`.
   Now Forgejo is accessible at [http://localhost:3000](http://localhost:3000).

### Unit tests

```bash
# install the unittest plugin
$ helm plugin install https://github.com/helm-unittest/helm-unittest

# run the unittests
make unittests
```

See [plugin documentation](https://github.com/helm-unittest/helm-unittest/blob/main/DOCUMENT.md) for usage instructions.

## Release process

1. Create a tag following the tagging schema
1. Push the tag
1. Let CI do it's work
