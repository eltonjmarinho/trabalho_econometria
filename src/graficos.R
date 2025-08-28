# ================================================================
# GRÁFICOS RAIS-PB — anos 2021 a 2024 (em box 2x2)
# ================================================================

library(dplyr)
library(ggplot2)
library(gridExtra)   # para grid.arrange

prep_base <- function(df) {
  df %>%
    rename(
      sexo         = `Sexo Trabalhador`,
      escolaridade = `Escolaridade após 2005`,
      idade        = `Idade`,
      rem_med      = `Vl Remun Média Nom`,
      horas        = `Qtd Hora Contr`,
      vic_ativ     = `Vínculo Ativo 31/12`
    ) %>%
    filter(vic_ativ == 1) %>%
    mutate(
      idade = suppressWarnings(as.numeric(as.character(idade))),
      rem_med = suppressWarnings(as.numeric(as.character(rem_med))),
      horas = suppressWarnings(as.numeric(as.character(horas))),
      sexo = factor(
        suppressWarnings(as.numeric(as.character(sexo))),
        levels = c(1, 2),
        labels = c("Homem", "Mulher")
      ),
      escolaridade = factor(
        suppressWarnings(as.numeric(as.character(escolaridade))),
        levels = c(5, 6, 7, 8, 9, 10, 11),
        labels = c("EF completo", "EM incompleto", "EM completo",
                   "Sup. incompleto", "Sup. completo", "Mestrado", "Doutorado")
      )
    ) %>%
    select(sexo, escolaridade, idade, rem_med, horas)
}

anos <- 2021:2024

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
# 1) HISTOGRAMAS DA IDADE — 2x2
# ================================================================
graficos_idade <- lapply(anos, function(a) {
  ggplot(filter(dados_todos, Ano == a), aes(x = idade)) +
    geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
    labs(title = paste("Distribuição da Idade -", a),
         x = "Idade (anos)", y = "Frequência") +
    theme_minimal()
})
grid.arrange(grobs = graficos_idade, ncol = 2)

# ================================================================
# 2) BOXPLOTS DA REMUNERAÇÃO — 2x2
# ================================================================
lim_sup <- suppressWarnings(quantile(dados_todos$rem_med, 0.95, na.rm = TRUE))
graficos_rem <- lapply(anos, function(a) {
  ggplot(filter(dados_todos, Ano == a), aes(x = Ano, y = rem_med)) +
    geom_boxplot(outlier.alpha = 0.2, fill = "tomato") +
    coord_cartesian(ylim = c(0, lim_sup)) +
    labs(title = paste("Remuneração Média -", a),
         x = "Ano", y = "Remuneração (R$)") +
    theme_minimal()
})
grid.arrange(grobs = graficos_rem, ncol = 2)

# ================================================================
# 3) LINHA DA MÉDIA SALARIAL — único gráfico
# ================================================================
dados_media_sal <- dados_todos %>%
  group_by(Ano) %>%
  summarise(media_salario = mean(rem_med, na.rm = TRUE), .groups = "drop")

p3 <- ggplot(dados_media_sal, aes(x = Ano, y = media_salario, group = 1)) +
  geom_line(linewidth = 1.2, color = "blue") +
  geom_point(size = 3, color = "red") +
  labs(title = "Média Salarial (R$) — 2021 a 2024",
       x = "Ano", y = "Média da remuneração (R$)") +
  theme_minimal()
print(p3)

# ================================================================
# 4) BARRAS DA ESCOLARIDADE — 2x2
# ================================================================
dados_escolaridade <- dados_todos %>%
  filter(!is.na(escolaridade)) %>%
  group_by(Ano, escolaridade) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  mutate(pct = 100 * n / sum(n)) %>%
  ungroup()

graficos_esc <- lapply(anos, function(a) {
  ggplot(filter(dados_escolaridade, Ano == a),
         aes(x = escolaridade, y = pct)) +
    geom_col(fill = "darkgreen") +
    labs(title = paste("Escolaridade -", a),
         x = "Escolaridade", y = "Percentual (%)") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 35, hjust = 1))
})
grid.arrange(grobs = graficos_esc, ncol = 2)

# ================================================================
# 5) BARRAS DE SEXO — 2x2
# ================================================================
dados_sexo <- dados_todos %>%
  filter(!is.na(sexo)) %>%
  group_by(Ano, sexo) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  mutate(pct = 100 * n / sum(n)) %>%
  ungroup()

graficos_sexo <- lapply(anos, function(a) {
  ggplot(filter(dados_sexo, Ano == a), aes(x = sexo, y = pct)) +
    geom_col(fill = "purple") +
    labs(title = paste("Distribuição por Sexo -", a),
         x = "Sexo", y = "Percentual (%)") +
    theme_minimal()
})
grid.arrange(grobs = graficos_sexo, ncol = 2)







