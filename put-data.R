library(data.table)
library(fst)
library(qs)
library(hutilscpp)
library(hutils)
library(healthyAddress)
library(default)
default(fread) <- list(na.strings = c("", "NA"), sep = "|", showProgress = FALSE, integer64 = "character", nThread = 8L)


PSMA_PATH <- "G:/PSMA-202311/G-NAF/G-NAF NOVEMBER 2023/Standard/"
PSMA_PATH <- "G:/PSMA-202405/g-naf_may24_allstates_gda2020_psv_1015/G-NAF/G-NAF MAY 2024/Standard/"
.ste_chars <- c("NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT", "OT")

PSMA_ADDRESS_LATLON <-
  lapply(.ste_chars, function(ste) {
    ad <- fread(file.path(PSMA_PATH, paste0(ste, "_ADDRESS_DETAIL_psv.psv")),
                select = c("ADDRESS_DETAIL_PID",
                           "ADDRESS_SITE_PID",
                           "FLAT_NUMBER",
                           "NUMBER_FIRST",
                           "NUMBER_LAST",
                           "POSTCODE",
                           "STREET_LOCALITY_PID"))

    as <- fread(file.path(PSMA_PATH, paste0(ste, "_STREET_LOCALITY_psv.psv")),
                select = c("STREET_LOCALITY_PID",
                           "STREET_NAME",
                           "STREET_TYPE_CODE"))
    as[, "STREET_TYPE_CODE" := chmatch(STREET_TYPE_CODE, .permitted_street_type_ord())]

    ag <- fread(file.path(PSMA_PATH, paste0(ste, "_ADDRESS_DEFAULT_GEOCODE_psv.psv")),
                select = c("ADDRESS_DETAIL_PID",
                           "LONGITUDE",
                           "LATITUDE"))
    ad[ag, c("lat", "lon") := list(i.LATITUDE, i.LONGITUDE), on = "ADDRESS_DETAIL_PID"]
    ad[, c_latlon := healthyAddress:::compress_latlon_general(lat, lon, nThread = 8L)]
    ad[, c("lat", "lon") := NULL]
    ad[as, c("STREET_NAME", "STREET_TYPE_CODE") := list(HashStreetName(i.STREET_NAME), i.STREET_TYPE_CODE),
       on = "STREET_LOCALITY_PID"]
    ad[, STREET_LOCALITY_PID := NULL]
    ad[, ADDRESS_DETAIL_PID := NULL]
    qs::qsave(ad, paste0(ste, "_latlon.qs"))
    ad
  })

