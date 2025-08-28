# ====================================================================
# SCRIPT MESTRE PARA EXECUÇÃO DO PIPELINE DE DADOS
# ====================================================================
#
# Este script executa todas as etapas do pipeline de dados em ordem.
#
# Para executar o pipeline completo, abra o R/RStudio e rode no console:
# source('run_pipeline.R')
#
# ====================================================================

# Função para imprimir mensagens de status
log_message <- function(stage, message) {
  cat(paste0("\n", strrep("-", 50), "\n"))
  cat(paste0("--- ", stage, ": ", message, " ---
"))
  cat(paste0(strrep("-", 50), "\n"))
}

# --- MENU DE SELEÇÃO DE ETAPAS ---
display_menu <- function() {
  cat("\n=========================================\n")
  cat("=== SELEÇÃO DE ETAPAS DO PIPELINE ===\n")
  cat("=========================================\n")
  cat("1. Executar Tudo\n")
  cat("2. Instalar Dependências\n")
  cat("3. Aquisição e Processamento dos Dados\n")
  cat("4. Executar Notebook de Análise Estatística\n")
  cat("0. Sair\n")
  cat("=========================================\n")
  choice <- readline(prompt = "Escolha uma opção: ")
  return(as.numeric(choice))
}

# Loop principal do menu
run_all_steps <- FALSE
selected_step <- -1

while (selected_step == -1) {
  choice <- display_menu()
  if (choice == 1) {
    run_all_steps <- TRUE
    selected_step <- 1 # Dummy value to exit loop
  } else if (choice >= 2 && choice <= 4) {
    selected_step <- choice
  } else if (choice == 0) {
    cat("Saindo do pipeline. Até mais!\n")
    quit(save = "no")
  } else {
    cat("Opção inválida. Por favor, escolha um número entre 0 e 4.\n")
  }
}

# --- ETAPA 1: Instalar dependências ---
if (run_all_steps || selected_step == 2) {
  log_message("ETAPA 1 de 3", "Verificando e instalando pacotes")
  tryCatch({
      source('install_packages.R')
      cat("Pacotes verificados/instalados com sucesso.\n")
  }, error = function(e) {
      stop(paste("ERRO na Etapa 1 (instalação de pacotes):", e$message))
  })
}

# --- ETAPA 2: Aquisição e processamento dos dados ---
if (run_all_steps || selected_step == 3) {
  log_message("ETAPA 2 de 3", "Baixando e processando dados da RAIS")
  tryCatch({
      source('src/data_acquisition/download_rais.R')
  }, error = function(e) {
      stop(paste("ERRO na Etapa 2 (aquisição de dados):", e$message))
  })
}

# --- ETAPA 3: Executar Notebook de Análise Estatística ---
if (run_all_steps || selected_step == 4) {
  log_message("ETAPA 3 de 3", "Executando o Notebook de Análise Estatística")
  tryCatch({
      # Certifique-se de que o Jupyter está instalado e acessível no PATH
      # O --to notebook --execute executa o notebook e salva as saídas
      # O --output_dir especifica o diretório de saída
      # O --output especifica o nome do arquivo de saída
      system("jupyter nbconvert --to notebook --execute notebooks/analise_estatistica.ipynb --output-dir notebooks/ --output analise_estatistica_executed.ipynb", intern = TRUE)
      cat("Notebook 'analise_estatistica.ipynb' executado com sucesso.\n")
  }, error = function(e) {
      stop(paste("ERRO na Etapa 3 (execução do notebook):", e$message))
  })
}



if (selected_step != -1) { # Only show success message if something was executed
  cat("\n=========================================\n")
  cat("=== PIPELINE EXECUTADO COM SUCESSO! ===\n")
  cat("=========================================\n")
}