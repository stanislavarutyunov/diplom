resource "yandex_compute_snapshot_schedule" "snapschedule" {
  name = "snapshotschedule"

  schedule_policy {
    expression = "0 0 ? * *"
  }

  snapshot_count = 1

  snapshot_spec {
    description = "daily-snapshot"
  }

  disk_ids = ["${yandex_compute_instance.webserver["web1"].boot_disk[0].disk_id}", "${yandex_compute_instance.webserver["web2"].boot_disk[0].disk_id}", "${yandex_compute_instance.vm-3.boot_disk[0].disk_id}", "${yandex_compute_instance.vm-4.boot_disk[0].disk_id}", "${yandex_compute_instance.vm-5.boot_disk[0].disk_id}", "${yandex_compute_instance.vm-6.boot_disk[0].disk_id}", "${yandex_compute_instance.vm-7.boot_disk[0].disk_id}"]
}

