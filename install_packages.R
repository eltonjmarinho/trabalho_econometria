# Script para instalar pacotes necessários para o projeto.
# Para executar, abra o R ou RStudio e rode o comando:
# source('install_packages.R')

# Lista de pacotes a serem instalados
packages <- c(
  "tidyverse",  # Coleção de pacotes para ciência de dados (ggplot2, dplyr, tidyr, etc.)
  "data.table", # Para manipulação eficiente de grandes data.frames
  "rmarkdown",  # Para criar relatórios e notebooks
  "here",       # Para gerenciamento de caminhos de arquivos
  "progress",   # Para barras de progresso
  "beepr",      # Para notificações sonoras
  "moments",    # Para cálculo de momentos estatísticos (assimetria, curtose)
  "gridExtra",   # Para arranjar múltiplos gráficos em uma grade
  "DT",         # Para tabelas interativas
  "kableExtra"  # Para formatação de tabelas em HTML e PDF
)

# Verifica quais pacotes já estão instalados e instala apenas os que faltam
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

# Mensagem de conclusão
print("Verificação e instalação de pacotes concluída.")
