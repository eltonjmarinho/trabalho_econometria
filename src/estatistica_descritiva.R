library(dplyr)
library(moments)  # para skewness e kurtosis

# --- paths e arquivos ---
base_path <- "c:/analise_estatistica/data/processed/"
anos      <- c(2021, 2022, 2023, 2024)
arquivos  <- c("rais_pb_2021.rda",
               "rais_pb_2022.rda",
               "rais_pb_2023.rda",
               "rais_pb_2024%20Parcial.rda")

# --- função estatística descritiva ---
estat_desc <- function(df) {
  df <- df %>%
    rename(
      idade        = `Idade`,
      horas        = `Qtd Hora Contr`,
      rem_med      = `Vl Remun Média Nom`
    ) %>%
    filter(`Vínculo Ativo 31/12` == 1) %>%
    mutate(
      idade   = suppressWarnings(as.numeric(as.character(idade))),
      horas   = suppressWarnings(as.numeric(as.character(horas))),
      rem_med = suppressWarnings(as.numeric(as.character(rem_med)))
    )

  vars <- c("idade", "horas", "rem_med")
  nomes <- c("Idade", "Horas Contratuais", "Remuneração Média (R$)")

  resultados <- lapply(seq_along(vars), function(i) {
    v <- vars[i]
    nome <- nomes[i]
    x <- df[[v]]
    x <- x[!is.na(x)]
    if (length(x) == 0) {
      c(Variável = nome, Média = NA, Mediana = NA,
        `Desvio-padrão` = NA, Mínimo = NA, Máximo = NA,
        P25 = NA, P75 = NA, Assimetria = NA, Curtose = NA)
    } else {
      c(
        Variável = nome,
        Média     = mean(x),
        Mediana   = median(x),
        `Desvio-padrão` = sd(x),
        Mínimo    = min(x),
        Máximo    = max(x),
        P25       = quantile(x, 0.25),
        P75       = quantile(x, 0.75),
        Assimetria = skewness(x),
        Curtose    = kurtosis(x)
      )
    }
  })

  resultados <- do.call(rbind, resultados) %>% as.data.frame()
  rownames(resultados) <- NULL
  resultados
}

# --- loop por ano ---
for (i in seq_along(anos)) {
  file_name <- arquivos[i]
  full_path <- paste0(base_path, file_name)

  if (file.exists(full_path)) {
    message(paste("Carregando:", full_path))
    temp_env <- new.env()
    load(full_path, envir = temp_env)
    obj <- get(ls(temp_env)[1], envir = temp_env)

    cat("\n============================\n")
    cat(" Estatística Descritiva -", anos[i], "\n")
    cat("============================\n")
    tabela <- estat_desc(obj)
    print(tabela, row.names = FALSE, digits = 3)
  } else {
    warning("Arquivo não encontrado: ", full_path)
  }
}

