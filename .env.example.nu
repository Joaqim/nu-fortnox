export-env {
    $env.DB_CONNECTION_STRING = "mongodb://<login>:<password>@localhost:27017/my-database"
    $env._FORTNOX_USE_CACHE = true
    $env._FORTNOX_DB_CREDENTIALS_QUERY = '{"provider": "fortnox"}'
}