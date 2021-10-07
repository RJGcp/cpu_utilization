provider "google" {
  project = var.project
}
resource "google_monitoring_notification_channel" "basic" {
  project      = var.project
  display_name = "CPU Utilization Email Channel"
  type         = "email"
  labels = {
    email_address = var.email-id
  }
}

data "google_monitoring_notification_channel" "Alerts" {
  display_name = "Alerts"
}

# data "google_monitoring_group" "king-of-kings" {
#   display_name = "king-of-kings"
# }

resource "google_monitoring_group" "parent" {
  display_name = "New Test SubGroup"
  filter = "resource.metadata.region=\"us-east1\""
}

resource "google_monitoring_alert_policy" "cpu_utilization" {
  depends_on = [google_monitoring_notification_channel.basic,google_monitoring_group.parent]
  project    = var.project
  enabled    = "true"

  display_name = "${var.project}-cpu-utilization-alert"

  combiner = "AND"
  conditions {
    display_name = "Critical: Project[${var.project}] GCE instance CPU Utilization is 0%"
    condition_absent {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND group.id=\"${google_monitoring_group.parent.id}\""
      duration        = "3600s"
    # condition_threshold {
    #   filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
    #   duration        = "3600s"
    #   comparison = ""
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_NONE"
        group_by_fields = [
          "resource.project_id", "resource.label.instance_name"
        ]
      }
    }  
  }
  notification_channels = ["${data.google_monitoring_notification_channel.Alerts.id}"]
  # ["${google_monitoring_notification_channel.basic.id}"]
}