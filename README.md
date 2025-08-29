# Projeto de Análise Estatística de Dados RAIS-PB

Este projeto tem como objetivo realizar uma análise estatística dos dados da RAIS (Relação Anual de Informações Sociais) para o estado da Paraíba (PB). O pipeline de análise abrange desde a aquisição e processamento dos dados brutos até a geração de relatórios e visualizações.

## Estrutura do Projeto

- `data/`: Contém os dados brutos (`raw/`) e processados (`processed/`).
- `src/`: Scripts R para aquisição e processamento de dados, e funções de análise.
- `notebooks/`: Notebooks Jupyter para análise exploratória e estatística.
- `reports/`: Relatórios gerados a partir das análises.
- `install_packages.R`: Script para instalação das dependências do projeto.
- `run_pipeline.R`: Script mestre para executar as etapas do pipeline.

## Como Executar o Pipeline

O pipeline pode ser executado através do script `run_pipeline.R`. Este script oferece um menu interativo para selecionar as etapas a serem executadas.

1.  **Abra o R/RStudio.**
2.  **Execute o script `run_pipeline.R` no console:**
    ```R
    source('run_pipeline.R')
    ```
3.  **Siga as instruções do menu** para escolher as etapas desejadas:
    *   **Instalar Dependências:** Garante que todos os pacotes R necessários estejam instalados.
    *   **Aquisição e Processamento dos Dados:** Baixa os dados brutos da RAIS e os processa para uso nas análises.
    *   **Executar Notebook de Análise Estatística:** Executa o notebook Jupyter principal, gerando os resultados da análise.

## Dependências

O projeto utiliza pacotes R como `dplyr`, `tidyr`, `ggplot2`, `gridExtra`, `moments`, entre outros. As dependências são gerenciadas e instaladas automaticamente pelo `install_packages.R`.

É Recomendado usar o VScode para executar o projeto.

Para a execução do notebook Jupyter, é necessário ter o `jupyter` e o `nbconvert` instalados e acessíveis no PATH do sistema.