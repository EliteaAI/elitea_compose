resource "random_id" "event_hmac_key" {
  byte_length = 32
}

resource "random_id" "rpc_hmac_key" {
  byte_length = 32
}

resource "random_id" "exposure_hmac_key" {
  byte_length = 32
}

resource "random_id" "indexer_hmac_key" {
  byte_length = 32
}

resource "random_id" "mesh_hmac_key" {
  byte_length = 32
}

resource "random_id" "fernet_key" {
  byte_length = 32
}

resource "random_id" "rnd_auth_secret" {
  byte_length = 32
}

resource "random_id" "rnd_main_secret" {
  byte_length = 32
}

resource "random_integer" "event_queue_rnd" {
  min = 1
  max = 254
}
