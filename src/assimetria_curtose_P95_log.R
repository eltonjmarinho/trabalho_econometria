# ================================================================
# GRÁFICOS DE DISTRIBUIÇÃO DA REMUNERAÇÃO (2021–2024)
# ================================================================

library(dplyr)
library(ggplot2)

# Função auxiliar para plotar histograma + densidade
plot_remuneracao <- function(dados, escala = "normal") {
  if (escala == "p95") {
    lim_sup <- quantile(dados$rem_med, 0.95, na.rm = TRUE)
    p <- ggplot(dados, aes(x = rem_med)) +
      geom_histogram(aes(y = ..density..), bins = 40, fill = "steelblue", alpha = 0.6) +
      stat_function(fun = dnorm,
                    args = list(mean = mean(dados$rem_med, na.rm = TRUE),
                                sd = sd(dados$rem_med, na.rm = TRUE)),
                    col = "red", size = 1) +
      coord_cartesian(xlim = c(0, lim_sup)) +
      facet_wrap(~Ano, ncol = 2) +
      labs(title = "Distribuição da Remuneração (até P95)",
           x = "Remuneração média (R$)", y = "Densidade") +
      theme_minimal()
    
  } else if (escala == "log") {
    p <- ggplot(dados, aes(x = rem_med)) +
      geom_histogram(aes(y = ..density..), bins = 40, fill = "steelblue", alpha = 0.6) +
      scale_x_log10() +
      facet_wrap(~Ano, ncol = 2) +
      labs(title = "Distribuição da Remuneração (escala log)",
           x = "Remuneração média (R$) — escala log10", y = "Densidade") +
      theme_minimal()
  }
  return(p)
}

# ================================================================
# Filtrar apenas os anos 2021–2024
# ================================================================
dados_rem <- dados_todos %>%
  filter(Ano %in% 2021:2024, !is.na(rem_med))

# ================================================================
# PLOTAR GRÁFICOS
# ================================================================

# 1) Distribuição até P95
p1 <- plot_remuneracao(dados_rem, escala = "p95")
print(p1)

# 2) Distribuição com escala log
p2 <- plot_remuneracao(dados_rem, escala = "log")
print(p2)
