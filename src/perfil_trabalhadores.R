library(dplyr)
library(tidyr)

# --- paths e arquivos ---
base_path <- "c:/analise_estatistica/data/processed/"
anos      <- c(2021, 2022, 2023, 2024)
arquivos  <- c("rais_pb_2021.rda",
               "rais_pb_2022.rda",
               "rais_pb_2023.rda",
               "rais_pb_2024%20Parcial.rda")

# --- carregar .rda em variáveis separadas rais_pb_<ano> ---
for (i in seq_along(anos)) {
  file_name <- arquivos[i]
  full_path <- paste0(base_path, file_name)

  var_name <- gsub(".rda$", "", file_name)
  var_name <- gsub("%20Parcial", "", var_name)

  if (file.exists(full_path)) {
    message(paste("Carregando:", full_path))
    temp_env <- new.env()
    load(full_path, envir = temp_env)
    obj <- get(ls(temp_env)[1], envir = temp_env)
    assign(var_name, obj, envir = .GlobalEnv)
    rm(temp_env, obj)
  } else {
    warning("Arquivo não encontrado: ", full_path)
  }
}

# --- função que calcula as métricas para um data frame RAIS ---
calc_metricas <- function(df) {
  df <- df %>%
    rename(
      mun          = `Município`,
      natjur       = `Natureza Jurídica`,
      cbo_ocup     = `CBO Ocupação 2002`,
      vic_ativ     = `Vínculo Ativo 31/12`,
      sexo         = `Sexo Trabalhador`,
      cor          = `Raça Cor`,
      idade        = `Idade`,
      escolaridade = `Escolaridade após 2005`,
      horas        = `Qtd Hora Contr`,
      rem_med      = `Vl Remun Média Nom`
    ) %>%
    filter(vic_ativ == 1)

  base_n <- nrow(df)

  df <- df %>%
    mutate(
      sexo         = suppressWarnings(as.numeric(as.character(sexo))),
      escolaridade = suppressWarnings(as.numeric(as.character(escolaridade))),
      horas        = suppressWarnings(as.numeric(as.character(horas))),
      rem_med      = suppressWarnings(as.numeric(as.character(rem_med))),
      idade        = suppressWarnings(as.numeric(as.character(idade)))
    )

  # 1) % homens
  n_sexo   <- sum(!is.na(df$sexo))
  pct_hom  <- if (n_sexo > 0) 100 * sum(df$sexo == 1, na.rm = TRUE) / n_sexo else NA_real_

  # 2–8) % por escolaridade (5=EF comp, 6=EM incomp, 7=EM comp, 8=Sup incomp, 9=Sup comp, 10=Mestrado, 11=Doutorado)
  esc_levels <- c(5,6,7,8,9,10,11)
  n_esc <- sum(!is.na(df$escolaridade))
  esc_pcts <- if (n_esc > 0) {
    sapply(esc_levels, function(lv) 100 * sum(df$escolaridade == lv, na.rm = TRUE) / n_esc)
  } else rep(NA_real_, length(esc_levels))

  # 9) média salarial mensal
  avg_sal <- if (any(!is.na(df$rem_med))) mean(df$rem_med, na.rm = TRUE) else NA_real_

  # 10) média da jornada semanal
  avg_horas <- if (any(!is.na(df$horas))) mean(df$horas, na.rm = TRUE) else NA_real_

  # 11) salário-hora (ponderado)
  ok <- !is.na(df$rem_med) & !is.na(df$horas) & df$horas > 0
  sal_hora <- if (any(ok)) sum(df$rem_med[ok], na.rm = TRUE) / sum(df$horas[ok] * 4, na.rm = TRUE) else NA_real_

  # 12) tamanho da base
  tam_base <- base_n

  # 13) média da idade
  avg_idade <- if (any(!is.na(df$idade))) mean(df$idade, na.rm = TRUE) else NA_real_

  c(
    pct_hom,
    esc_pcts,
    avg_sal,
    avg_horas,
    sal_hora,
    tam_base,
    avg_idade
  )
}

# --- nomes das métricas ---
metric_names <- c(
  "% de Homens",
  "% EF completo",
  "% EM incompleto",
  "% EM completo",
  "% Superior incompleto",
  "% Superior completo",
  "% Mestrado",
  "% Doutorado",
  "Média do salário mensal (R$)",
  "Média da jornada semanal (h)",
  "Salário-hora (R$)",
  "Tamanho da base (vínculos ativos)",
  "Média da idade (anos)"
)

summary_table <- data.frame(Métrica = metric_names, stringsAsFactors = FALSE)

# --- calcula e adiciona colunas por ano ---
for (ano in anos) {
  df_name <- paste0("rais_pb_", ano)
  if (exists(df_name, inherits = TRUE)) {
    df <- get(df_name, inherits = TRUE)
    vals <- tryCatch(calc_metricas(df), error = function(e) rep(NA_real_, length(metric_names)))
    summary_table[[as.character(ano)]] <- vals
  } else {
    warning("Data frame não encontrado: ", df_name)
    summary_table[[as.character(ano)]] <- rep(NA_real_, length(metric_names))
  }
}

# --- formatação (internacional: milhar=',' e decimal='.') ---
fmt <- function(x, i) {
  if (is.na(x)) return(NA)
  
  if (i %in% 1:8) {        # percentuais
    return(format(round(x,1), big.mark=",", decimal.mark="."))  
  } else if (i %in% 9) {   # média salarial
    return(format(round(x,2), big.mark=",", decimal.mark="."))  
  } else if (i %in% 10) {  # jornada semanal
    return(format(round(x,1), big.mark=",", decimal.mark="."))  
  } else if (i %in% 11) {  # salário-hora
    return(format(round(x,2), big.mark=",", decimal.mark="."))  
  } else if (i %in% 12) {  # tamanho da base
    return(format(round(x), big.mark=",", decimal.mark=".", scientific = FALSE))
  } else if (i %in% 13) {  # idade
    return(format(round(x,1), big.mark=",", decimal.mark="."))  
  }
}

for (j in 2:ncol(summary_table)) {
  summary_table[[j]] <- mapply(function(val, i) ifelse(is.na(val), NA, fmt(val, i)),
                               summary_table[[j]], seq_len(nrow(summary_table)))
}

cat("\nTabela de Resumo por Ano:\n")
print(summary_table, row.names = FALSE, right = FALSE)



