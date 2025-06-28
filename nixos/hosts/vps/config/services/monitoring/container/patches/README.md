# Grafana Dashboard Patches

Because we use the VictoriaMetrics datasource plugin instead of the default prometheus one, public
dashboards don't work out of the box. To fix this, these patches simply change the datasource type
to the correct one after downloading the JSON.
