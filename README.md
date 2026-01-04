## Requisitos
- `aria2c` para download paralelo dos arquivos `Estabelecimentos0..9.zip` direto do endpoint de “dados abertos CNPJ” da Receita Federal.
- `7z` (p7zip) para extrair os arquivos `.zip`.
- `clickhouse-local` para transformar os CSVs em Parquet.

## baixar-dados-estabelecimentos.sh
Script “tudo em uma tacada”: baixa os 10 arquivos `Estabelecimentos{0..9}.zip`, extrai todos e converte os `.ESTABELE` para um único `estabs.parquet` usando `clickhouse-local`.
No processo, renomeia/seleciona colunas (ex.: `cnpj_basico`, `nome_fantasia`, `situacao_cadastral`, `uf`, etc.) e grava Parquet com compressão `zstandard`.
Depois gera uma versão tratada filtrando linhas com situação cadastral ativa e nome fantasia não nulo/não vazio, remove temporários e finaliza deixando `estabs.parquet` como saída.

## baixar-dados-estabelecimentos-low-memory.sh
Versão de **baixo uso de memória**: processa cada parte separadamente, baixando `Estabelecimentos{i}.zip`, extraindo e gerando `estabs_{i}.parquet` em vez de carregar todos os CSVs de uma vez.

## separar-por-estado.sh
Lê o arquivo consolidado `estabs.parquet`, obtém a lista de UFs distintas e exporta um Parquet por UF no formato `estabs_<UF>.parquet`.
