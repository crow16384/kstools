## ============================================================
## ks_desc_coded() — hierarchically coded item summary
## ============================================================
## Returns raw counts (n, e) per SOC/PT row.
## Apply ks_n_pct(n, pop) afterwards to format values.
##
## Output columns:
##   ord0, ord   integer sort keys
##   <l1>        top-level code (SOC); tot_label for overall-total row
##   <l2>        lower-level code (PT); NA on total / SOC rows
##   n           distinct subject count
##   e           event count
##
## Rows where <l2> is NA are header / bold rows in a report.
## ============================================================

library(kstools)
library(dplyr)

## ------------------------------------------------------------------
## Synthetic AE dataset: 4 subjects, 2 SOCs, 4 PTs
## ------------------------------------------------------------------
ae <- data.frame(
  usubjid = c("01","01","01","02","02","03","03","04","04","04"),
  trt     = c( "A", "A", "A", "A", "A", "B", "B", "B", "B", "B"),
  soc     = c(
    "Cardiac disorders", "Nervous system disorders", "Nervous system disorders",
    "Cardiac disorders", "Nervous system disorders",
    "Cardiac disorders", "Nervous system disorders",
    "Cardiac disorders", "Nervous system disorders", "Nervous system disorders"
  ),
  pt = c(
    "Palpitation", "Headache", "Dizziness",
    "Tachycardia", "Headache",
    "Tachycardia", "Dizziness",
    "Palpitation", "Headache", "Dizziness"
  ),
  stringsAsFactors = FALSE
)

## ------------------------------------------------------------------
## 1. Raw counts — single arm
## ------------------------------------------------------------------
cat("=== 1. Raw counts (no formatting) ===\n\n")

raw <- ks_desc_coded(ae, id = usubjid, l1 = soc, l2 = pt)
print(as.data.frame(raw))

## ------------------------------------------------------------------
## 2. Add formatted value with ks_n_pct once pop is known
## ------------------------------------------------------------------
cat("\n\n=== 2. With formatted value (N=4) ===\n\n")

formatted <- raw |>
  mutate(value = ks_n_pct(n, totals = 4))

print(as.data.frame(formatted))

## ------------------------------------------------------------------
## 3. Multi-arm: group_modify() + ks_n_pct per arm
## ------------------------------------------------------------------
cat("\n\n=== 3. Multi-arm (A vs B) ===\n\n")

pop <- c(A = 5L, B = 5L)

per_arm <- ae |>
  group_by(trt) |>
  group_modify(
    ~ ks_desc_coded(.x, id = usubjid, l1 = soc, l2 = pt) |>
      mutate(value = ks_n_pct(n, totals = pop[.y$trt]))
  ) |>
  ungroup()

print(as.data.frame(per_arm[, c("trt","soc","pt","n","e","value")]))

## ------------------------------------------------------------------
## 4. Side-by-side arms joined as columns
## ------------------------------------------------------------------
cat("\n\n=== 4. Arms as columns (join on SOC/PT keys) ===\n\n")

arm_a <- ae |>
  filter(trt == "A") |>
  ks_desc_coded(id = usubjid, l1 = soc, l2 = pt) |>
  mutate(value_A = ks_n_pct(n, totals = pop["A"])) |>
  select(-n, -e)

arm_b <- ae |>
  filter(trt == "B") |>
  ks_desc_coded(id = usubjid, l1 = soc, l2 = pt) |>
  mutate(value_B = ks_n_pct(n, totals = pop["B"])) |>
  select(-n, -e)

combined <- left_join(arm_a, arm_b, by = c("ord0","soc","ord","pt"))
print(as.data.frame(combined))

## ------------------------------------------------------------------
## 5. Custom tot_label
## ------------------------------------------------------------------
cat("\n\n=== 5. Custom tot_label ===\n\n")

custom <- ks_desc_coded(ae, id = usubjid, l1 = soc, l2 = pt,
                         tot_label = "Subjects with any AE")

cat("Overall-total row:\n")
print(as.data.frame(custom[custom$ord0 == 1L, ]))

## ------------------------------------------------------------------
## 6. Medical history (different column names — same function)
## ------------------------------------------------------------------
cat("\n\n=== 6. Medical history (atc_grp / drug_name) ===\n\n")

mh <- data.frame(
  usubjid   = c("01","01","02","02","02","03"),
  atc_grp   = c("Cardiovascular","Cardiovascular","CNS","CNS","Cardiovascular","CNS"),
  drug_name = c("Atorvastatin","Aspirin","Sertraline","Melatonin","Lisinopril","Sertraline"),
  stringsAsFactors = FALSE
)

mh_res <- ks_desc_coded(mh,
                          id        = usubjid,
                          l1        = atc_grp,
                          l2        = drug_name,
                          tot_label = "Subjects with prior medication") |>
  mutate(value = ks_n_pct(n, totals = 5))

print(as.data.frame(mh_res))
