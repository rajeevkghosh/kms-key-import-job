provider "google" {
  project      = var.project
  #access_token = var.access_token
  credentials = file("../kms.json")
}

/*resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = "us_dev_abcd_fghi_dataset2_bqds2"
  friendly_name               = "test"
  description                 = "This is a test description"
  location                    = "US"
  default_table_expiration_ms = 3600000
  labels = {
    env                  = "default"
    application_division = "pci",
    application_name     = "demo",
    application_role     = "app",
    au                   = "0223092",
    created              = "20211122",
    data_compliance      = "pci",
    data_confidentiality = "pub",
    data_type            = "test",
    environment          = "dev",
    gcp_region           = "us",
    owner                = "hybridenv",
  }

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.cryptokey.id
  }
}
*/

resource "google_kms_crypto_key" "cryptokey" {
  name = var.keyring_key_name
  labels = {
    env                  = "default"
    application_division = "pci",
    application_name     = "demo",
    application_role     = "app",
    au                   = "0223092",
    created              = "20211122",
    data_compliance      = "pci",
    data_confidentiality = "pub",
    data_type            = "test",
    environment          = "dev",
    gcp_region           = "us",
    owner                = "hybridenv",
  }

  key_ring = data.google_kms_key_ring.keyring.id
  skip_initial_version_creation = true
  import_only = true
  #depends_on = ["google_kms_key_ring_import_job.import-job"]
}

data "google_kms_key_ring" "keyring" {
  name     = var.keyring_name
  location = var.keyring_location
}
resource "google_kms_key_ring_import_job" "import-job" {
  key_ring      = data.google_kms_key_ring.keyring.id
  import_job_id = var.keyring_import_job

  import_method    = "RSA_OAEP_3072_SHA1_AES_256"
  protection_level = "SOFTWARE"
}
resource "null_resource" "proto_descriptor" {
  provisioner "local-exec" {
    command = <<EOT
    /usr/bin/openssl rand 32 > ${var.key_path}/test.bin
    EOT
  }
}
resource "null_resource" "import" {

  provisioner "local-exec" {
    command = <<EOT
    gcloud kms keys versions import \
      --import-job ${var.keyring_import_job} \
      --location ${var.keyring_location} \
      --keyring ${var.keyring_name} \
      --key ${var.keyring_key_name} \
      --algorithm google-symmetric-encryption \
      --target-key-file ${var.key_path}/test.bin
    EOT
  }
}