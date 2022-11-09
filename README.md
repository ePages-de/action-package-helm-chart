# action-package-helm-chart
Github action to package helm charts

Wrapper around a script for packaging helm charts after building a ng service.

## Inputs

## `build-timestamp`

**Required** The build timestamp in the "yyyyMMddHHmmss" format. Ex: 20220106100059.

## `project-chart-name`

**Required** The chart name of this project (without ng- prefix). Ex: product-management.

## `helm-repo-url`

**Required** The repository URL.

## `artifactory-username`

**Required** The username to access the artifactory helm repo.

## `artifactory-password`

**Required** The password to access the artifactory helm repo.

## `has-messaging`

Whether the service generates a "message-artifacts-helm.yaml" file during build (typically when the service uses messaging). Default is "true"

## Outputs

## `chart-version`

The version of the chart that was published. Ex: 0.1.1641463259

## Example usage

```yaml
uses: ePages-de/action-package-helm-chart@v4
with:
    build-timestamp: ${{ needs.build.outputs.build-timestamp }} # generated during build
    project-chart-name: "product-finder"
    helm-repo-url: https://my-company.jfrog.io/my-project/helm-charts
    artifactory-username: ${{ secrets.CHART_REPO_USER }}
    artifactory-password: ${{ secrets.CHART_REPO_PASSWORD }}
```