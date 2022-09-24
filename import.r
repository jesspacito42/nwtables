download.file(
    "https://raw.githubusercontent.com/new-world-tools/datasheets-csv/main/LootTablesData/LootTables.csv", # nolint
    destfile = here::here("data", "LootTables.csv"),
    method = "curl"
)
download.file(
    "https://raw.githubusercontent.com/new-world-tools/datasheets-csv/main/LootBucketData/LootBuckets.csv", # nolint
    destfile = here::here("data", "LootBuckets.csv"),
    method = "curl"
)