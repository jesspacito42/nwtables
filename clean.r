library(data.table)
library(magrittr)
library(purrr)

# utils
remove_NA_cols <- function(DT) { 
    DT[, which(unlist(lapply(DT, function(x)!all(is.na(x))))), with=F]
}

remove_blank_cols <- function(DT) { 
    DT[, which(unlist(lapply(DT, function(x)!all(x == "")))), with=F]
}

# import
lt <- fread(here::here("data", "LootTables.csv")) %>%
    remove_NA_cols()

# indicator for row type
lt[grep("_Qty$", LootTableID), type := "Qty"]
lt[grep("_Probs$", LootTableID), type := "Probs"]
lt[!grep("(_Probs|_Qty)$", LootTableID), type := "Name"]

# clean up ID name
lt[, LootTableID := gsub("(_Probs|_Qty)$", "", LootTableID)]

# store col names
info_cols <- c("AND/OR", "RollBonusSetting", "Conditions")
item_cols <- names(lt)[grep("^(Item)", names(lt))]

# table metadata
# add a row number to preserve original order after keying
lt_info <- lt[type == "Name", .SD, .SDcols = c("LootTableID", info_cols)]
lt_info[, row := .I]
setkey(lt_info, LootTableID)

# table data
reshapeLT <- function(DT, id_cols) {
    ret <- melt(
        DT,
        id.vars = id_cols,
        measure.vars = patterns(
            "^(Item[[:digit:]]_Name)",
            "^(Item[[:digit:]]_Qty)",
            "^(Item[[:digit:]]_Probs)"
        ),
    variable.name = "ItemNumber",
    value.name = c("Name", "Qty", "Probs")
  ) %>%
    .[, .SD, .SDcols = c(id_cols, "ItemNumber", "Name", "Qty", "Probs")] %>%
    .[Name != ""] %>%
    remove_NA_cols() %>%
    remove_blank_cols() %>%
    .[, ItemNumber := NULL]
    ret[]
}
lt_subtables <- lt[, .SD, .SDcols = c("LootTableID", "type", item_cols)] %>%
    # long to wide, by loottable type (name, probs, or qty)
    # each row is a loottable w/columns Item1_Name, Item1_Probs, Item1_Qty, etc
    dcast(LootTableID ~ type, value.var = item_cols) %>%
    # wide to long, by item
    reshapeLT(id_cols = "LootTableID") %>%
    setkey(LootTableID)



# string containing all loot table item names; will be hidden
# allows for searching by item when child tables are collapsed
lt_hidden <- lt[
    type == "Name",
    .(hidden = trimws(do.call(paste, c(.SD, sep = " ")))),
    .SDcols = item_cols,
    keyby = LootTableID
]

# nest table data within metadata table
lt_nested <- lt_info[,
        .(details = list(
            cbind(" " = "", lt_subtables[LootTableID, .(Name, Qty, Probs)]) %>%
                purrr::transpose()
        )),
    keyby = LootTableID
]

# final table
# merge
lt_final <- lt_info[lt_hidden[lt_nested]] %>%
    # go back to original order, then delete ordering col
    setorder(row) %>%
    .[, row := NULL] %>%
    # add column on the left for the dropdown arrow button
    cbind(" " = "<i class=\"fas fa-angle-right\"></i>", .)
saveRDS(lt_final, "data/lt-nested.rds")