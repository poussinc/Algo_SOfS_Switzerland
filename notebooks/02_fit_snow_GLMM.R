##### Snow coverage GLMM per season - fit in R (lme4) and export the coefficients #####
##### Same models as "Model per saison1.R" (P. Timoner and C. Poussin, 2021)       #####
##### The coefficients are then used in Python (CP_Snow_GLMM_monthly.ipynb)       #####
#
# Run once (or when the model changes), e.g. in a terminal:
#   Rscript notebooks/02_fit_snow_GLMM.R      (from the repository root)
#
# Model per season:  ThrX ~ NDSI + (NDSI|Stations) + (NDSI|AltC) + (NDSI|Landcover)
#   ThrX = snow depth >= threshold of the season (DJF 1 cm, MAM 5 cm, JJA 15 cm, SON 15 cm)
# Prediction (as re.form = ~(NDSI|AltC)+(NDSI|Landcover)):
#   p = 1 / (1 + exp(-((b0 + u_AltC + u_LC) + (b1 + v_AltC + v_LC) * NDSI)))
# cutoff = threshold (0, 0.05, ..., 1) maximising the TSS, as biomod2::bm_FindOptimStat

library(lme4)

in_rds  <- "data/stations/dfCP.rds"            # run from the repository root
out_csv <- "data/model/glmm_R_coefs_saisons.csv"
dir.create(dirname(out_csv), showWarnings = FALSE)

############################# Data preparation (as in Model per saison1.R) #############
df <- readRDS(in_rds)
df$NDSI[df$NDSI > 1] <- NA
df$NDSI[df$NDSI < -1] <- NA
df <- df[complete.cases(df), ]
cat("rows:", nrow(df), "(must be 13100)\n")
df$AltC <- cut(df$Alt, breaks = c(0, 500, 1000, 1500, 2000, 2500, Inf), labels = c(1, 2, 3, 4, 5, 6))
df$Saisons <- factor(df$Saisons, levels = c("DJF", "MAM", "JJA", "SON"))
df$Landcover <- factor(df$Landcover, levels = c("non forested", "Sparsely forested", "forested"), labels = c(1, 2, 3))

# TSS-optimal cutoff (prediction >= threshold, as biomod2)
best_tss <- function(fit, obs, th = seq(0, 1, 0.05)) {
  tss <- sapply(th, function(t) {
    p <- fit >= t
    sum(p & obs == 1) / sum(obs == 1) + sum(!p & obs == 0) / sum(obs == 0) - 1
  })
  k <- which.max(tss)
  c(tss = tss[k], cutoff = th[k])
}

############################# One model per season ######################################
thrSnow <- c(DJF = 1, MAM = 5, JJA = 15, SON = 15)
out <- list()
for (s in names(thrSnow)) {
  d <- df[df$Saisons == s, ]
  d$ThrX <- ifelse(d$Snow >= thrSnow[[s]], 1, 0)
  m <- glmer(ThrX ~ (NDSI | Stations) + NDSI + (NDSI | AltC) + (NDSI | Landcover), data = d,
             family = binomial("logit"), control = glmerControl(optimizer = "nloptwrap", optCtrl = list(maxfun = 2e5)))
  pr <- predict(m, type = "response", re.form = ~(NDSI | AltC) + (NDSI | Landcover))
  bt <- best_tss(pr, d$ThrX)
  fe <- fixef(m)
  re <- ranef(m)
  cat(sprintf("%s: n=%d, snow >= %d cm: %.1f%% | b0=%.4f b1=%.4f | TSS=%.3f cutoff=%.2f\n",
              s, nrow(d), thrSnow[[s]], 100 * mean(d$ThrX), fe[1], fe[2], bt[["tss"]], bt[["cutoff"]]))
  out[[length(out) + 1]] <- data.frame(season = s, effect = "fixed", level = NA, intercept = fe[[1]], slope = fe[[2]],
                                       cutoff = bt[["cutoff"]], tss = bt[["tss"]], snow_thr_cm = thrSnow[[s]])
  for (g in c("AltC", "Landcover")) {
    r <- re[[g]]
    out[[length(out) + 1]] <- data.frame(season = s, effect = g, level = rownames(r), intercept = r[, "(Intercept)"],
                                         slope = r[, "NDSI"], cutoff = NA, tss = NA, snow_thr_cm = thrSnow[[s]])
  }
}
res <- do.call(rbind, out)
write.csv(res, out_csv, row.names = FALSE)
cat("written:", out_csv, "\n")
