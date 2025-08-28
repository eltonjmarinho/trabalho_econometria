# ====================================================================
# Script para download, extração e filtragem de microdados da RAIS
# ====================================================================

# --- 1. CONFIGURAÇÃO INICIAL ---

# Certifique-se de que os pacotes necessários estão instalados.
# Se não estiverem, execute o script na raiz do projeto:
# source('install_packages.R')

library(data.table)
library(dplyr)
library(here)
library(progress)
library(beepr)
# RCurl removido, pois a lógica de download foi adaptada

# --- 2. PARÂMETROS ---

# Anos de interesse (2024 está como "2024 Parcial" no servidor)
anos <- c("2021", "2022", "2023", "2024%20Parcial")

# Variáveis de interesse (adaptado do script do usuário)
variaveis_selecionadas <- c(
    'Natureza Jurídica',"CBO Ocupação 2002","Vínculo Ativo 31/12","Sexo Trabalhador",'Raça Cor',
    'Idade','Faixa Etária','Qtd Hora Contr','Escolaridade após 2005',"Vl Remun Média Nom",'Tempo Emprego',
    "Faixa Tempo Emprego","Município"
)

# A Paraíba pertence à base do Nordeste
base_regiao <- "RAIS_VINC_PUB_NORDESTE"

# Código IBGE do estado da Paraíba (para filtro)
codigo_uf_pb <- "25"

# --- 3. DOWNLOAD E PROCESSAMENTO ---

# Cria os diretórios principais
dir.create(here("data", "raw"), showWarnings = FALSE)
dir.create(here("data", "processed"), showWarnings = FALSE)

# Baixa o executável 7-Zip
path_7za <- here("7za.exe")
if (!file.exists(path_7za)) {
    download.file('http://cemin.wikidot.com/local--files/raisrm/7za.exe', destfile = path_7za, mode = 'wb')
}

options(timeout = 600)

# Barra de progresso principal (para os anos)
pb <- progress_bar$new(
  format = "Progresso geral [:bar] :percent em :elapsed | ETA: :eta",
  total = length(anos), 
  clear = FALSE, 
  width = 70
)

cat("\nIniciando o download e processamento dos dados da RAIS...\n")

# Loop principal
for (ano in anos) {
    
    ano_limpo <- gsub(" Parcial", "", ano)
    cat(paste0("\n", strrep("=", 70), "\n"))
    cat(paste0("=== PROCESSANDO ANO: ", ano_limpo, " ===\n"))
    cat(paste0(strrep("=", 70), "\n"))

    # Cria um diretório temporário para os arquivos brutos do ano
    path_raw_ano <- here("data", "raw", ano_limpo)
    dir.create(path_raw_ano, showWarnings = FALSE)

    # Salva o diretório de trabalho atual e muda para o diretório do ano
    old_wd <- getwd()
    setwd(path_raw_ano)

    max_tentativas <- 10 # Adaptado do script do usuário
    sucesso_ano <- FALSE

    for (tentativa in 1:max_tentativas) {
        cat(sprintf("--- Tentativa %d de %d para o ano %s ---\n", tentativa, max_tentativas, ano_limpo))
        
        tryCatch({
            # --- Etapa 1: Download (Adaptado do script do usuário) ---
            cat("--- Etapa 1/5: Download ---\n")
            nome_arquivo_7z <- paste0(base_regiao, ".7z") # Apenas o nome do arquivo
            url_ftp <- paste0('ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/', ano, '/', nome_arquivo_7z)
            
            # Apaga arquivo antigo se existir, para garantir um novo download
            if(file.exists(nome_arquivo_7z)) file.remove(nome_arquivo_7z)
            
            download.file(url_ftp, destfile = nome_arquivo_7z, mode = 'wb', method = 'libcurl', quiet = FALSE)
            if (!file.exists(nome_arquivo_7z)) { stop("Arquivo .7z não foi encontrado após o download.") }
            cat("Download concluído.\n")

            # --- Etapa 2: Extração (Adaptado do script do usuário) ---
            cat("\n--- Etapa 2/5: Extração ---\n")
            path_arquivo_txt <- paste0(base_regiao, ".txt") # Apenas o nome do arquivo
            
            # Comando de extração simplificado, extrai para o WD atual
            status <- system(paste0(shQuote(path_7za), ' e ', shQuote(nome_arquivo_7z), ' -y', sep=''))
            if (status != 0) { stop(paste("Falha na extração. Código de erro:", status)) }
            cat("Arquivo extraído com sucesso.\n")

            # --- Etapa 3: Leitura e Filtragem ---
            cat("\n--- Etapa 3/5: Leitura e Filtragem ---\n")
            dados_rais <- suppressWarnings(fread(
                file = path_arquivo_txt, 
                sep = ';', 
                select = variaveis_selecionadas, 
                header = TRUE, 
                encoding = 'Latin-1', 
                showProgress = TRUE
            ))
            dados_pb <- dados_rais %>% filter(startsWith(as.character(Município), codigo_uf_pb))
            cat("Dados filtrados para Paraíba.\n")

            # --- Etapa 4: Salvando ---
            cat("\n--- Etapa 4/5: Salvando arquivo processado ---\n")
            # Salva na pasta processed principal, não na pasta do ano
            path_final_rda <- here("data", "processed", paste0("rais_pb_", ano_limpo, ".rda"))
            save(dados_pb, file = path_final_rda)
            cat("Arquivo salvo em:", path_final_rda, "\n")

            # --- Etapa 5: Limpeza ---
            cat("\n--- Etapa 5/5: Limpeza da pasta de dados brutos do ano ---\n")
            # Remove os arquivos temporários do diretório atual
            file.remove(nome_arquivo_7z, path_arquivo_txt)
            # Retorna ao diretório original antes de apagar a pasta do ano
            setwd(old_wd)
            unlink(path_raw_ano, recursive = TRUE) # Apaga a pasta do ano
            gc()
            cat("Limpeza concluída.\n")

            # Notificação sonora de sucesso e sai do loop de tentativas
            beepr::beep("treasure")
            sucesso_ano <- TRUE

        }, error = function(e) {
            cat("\nERRO na tentativa:", e$message, "\n")
            # Limpa os arquivos temporários antes de tentar novamente
            if(file.exists(nome_arquivo_7z)) file.remove(nome_arquivo_7z)
            if(file.exists(path_arquivo_txt)) file.remove(path_arquivo_txt)
            # Retorna ao diretório original antes de apagar a pasta do ano
            setwd(old_wd)
            unlink(path_raw_ano, recursive = TRUE) # Apaga a pasta do ano
            dir.create(path_raw_ano, showWarnings = FALSE) # Recria para a próxima tentativa
        })

        if (sucesso_ano) { break }
        if (tentativa < max_tentativas) {
            cat(sprintf("Aguardando 60 segundos antes de tentar novamente...\n")) # Adaptado do script do usuário
            Sys.sleep(60)
        }
    } # Fim do loop de tentativas

    # Retorna ao diretório original se o loop de tentativas falhou e não retornou
    if (!sucesso_ano && getwd() != old_wd) {
        setwd(old_wd)
        unlink(path_raw_ano, recursive = TRUE) # Apaga a pasta do ano se falhou
    }

    if (!sucesso_ano) {
        cat(sprintf("\nFALHA PERSISTENTE: Não foi possível processar o ano %s após %d tentativas.\n", ano_limpo, max_tentativas))
        beepr::beep("warning")
    }

    # Atualiza a barra de progresso principal
    pb$tick()
}

# --- 4. LIMPEZA FINAL ---
file.remove(path_7za)

cat("\nProcesso geral concluído!\n")
beepr::beep("fanfare") # Som final de sucesso para todo o pipeline