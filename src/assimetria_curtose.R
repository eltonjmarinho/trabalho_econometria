# ================================================================
# GRÁFICOS DE CURTOSE E ASSIMETRIA POR ANO (2021–2024) - BOX 2x2
# ================================================================

library(dplyr)
library(ggplot2)
library(gridExtra)   # para grid.arrange

# --- funções manuais ---
skewness_manual <- function(x) {
  x <- x[!is.na(x)]
  m <- mean(x)
  s <- sd(x)
  mean(((x - m)/s)^3)
}

kurtosis_manual <- function(x) {
  x <- x[!is.na(x)]
  m <- mean(x)
  s <- sd(x)
  mean(((x - m)/s)^4)
}

# --- função de limpeza ---
prep_base <- function(df) {
  df %>%
    rename(
      idade   = `Idade`,
      rem_med = `Vl Remun Média Nom`,
      vic_ativ = `Vínculo Ativo 31/12`
    ) %>%
    filter(vic_ativ == 1) %>%
    mutate(
      idade   = suppressWarnings(as.numeric(as.character(idade))),
      rem_med = suppressWarnings(as.numeric(as.character(rem_med)))
    ) %>%
    select(idade, rem_med)
}

anos <- 2021:2024

# --- empilhar dados ---
dados_todos <- lapply(anos, function(ano) {
  nm <- paste0("rais_pb_", ano)
  if (exists(nm, inherits = TRUE)) {
    df <- get(nm, inherits = TRUE) %>% prep_base()
    df$Ano <- factor(ano)
    df
  } else {
    warning("Base não encontrada: ", nm)
    NULL
  }
}) %>% bind_rows()

if (nrow(dados_todos) == 0) {
  stop("Nenhum dado disponível para 2021–2024.")
}

# ================================================================
# GRÁFICOS - UM POR ANO, EM BOX 2x2
# ================================================================

# função para plotar distribuição de uma variável
plot_dist <- function(df, var, ano, titulo) {
  ggplot(df, aes_string(x = var)) +
    geom_histogram(aes(y = ..density..), bins = 30, fill = "steelblue", alpha = 0.6) +
    geom_density(color = "red", linewidth = 1) +
    labs(title = paste0(titulo, " - ", ano),
         x = var, y = "Densidade") +
    theme_minimal()
}

# listas de gráficos (idade e remuneração)
graficos_idade <- lapply(anos, function(a) {
  df <- filter(dados_todos, Ano == a)
  plot_dist(df, "idade", a, "Distribuição da Idade")
})

graficos_sal <- lapply(anos, function(a) {
  df <- filter(dados_todos, Ano == a)
  plot_dist(df, "rem_med", a, "Distribuição da Remuneração")
})

# exibir em box 2x2
grid.arrange(grobs = graficos_idade, ncol = 2)
grid.arrange(grobs = graficos_sal, ncol = 2)

# ================================================================
# TABELA DE ASSIMETRIA E CURTOSE
# ================================================================
estatisticas <- dados_todos %>%
  group_by(Ano) %>%
  summarise(
    Assimetria_Idade = skewness_manual(idade),
    Curtose_Idade    = kurtosis_manual(idade),
    Assimetria_Sal   = skewness_manual(rem_med),
    Curtose_Sal      = kurtosis_manual(rem_med),
    .groups = "drop"
  )

print(estatisticas)



