#!/bin/bash

for i in {0..9}; do
    if [ ! -f "Estabelecimentos${i}.zip" ]; then
        aria2c -s 16 -k 1M "https://arquivos.receitafederal.gov.br/dados/cnpj/dados_abertos_cnpj/$(date +"%Y-%m")/Estabelecimentos${i}.zip";
    else
        echo "O arquivo já existe, pulando.";
    fi

    files=(*.ESTABELE);
    if [ ! -e "${files[0]}" ]; then
        7z x Estabelecimentos${i}.zip;
        rm Estabelecimentos${i}.zip;
        unset files;
    else
        echo "O arquivo já existe, pulando.";
        unset files;
    fi

    files=(*.ESTABELE);
    if [ -e "${files[0]}" ]; then
        clickhouse-local --query "SELECT c1 as cnpj_basico,c2 as cnpj_ordem,c3 as cnpj_dv,c4 as identificador,c5 as nome_fantasia,c6 as situacao_cadastral,c7 as data_situacao_cadastral,c8 as motivo_situacao_cadastral,c9 as nome_cidade_exterior,c10 as pais,c11 as data_inicio_atividade,c12 as cnae_principal,c13 as cnaes_secundarios,c14 as tipo_logradouro,c15 as lougradouro,c16 as numero,c17 as complemento,c18 as bairro,c19 as cep,c20 as uf,c21 as municipio,c22 as ddd_1,c23 as telefone_1,c24 as ddd_2,c25 as telefone_2,c26 as ddd_fax,c27 as fax,c28 as email,c29 as situacao_especial,c30 as data_situacao_especial FROM file('*.ESTABELE') INTO OUTFILE 'estabs_${i}.parquet' SETTINGS format_csv_delimiter=';', output_format_parquet_compression_method = 'zstd'";
        rm *.ESTABELE;
        unset files;
    else
        echo "Nenhum arquivo csv foi encontrado, pulando.";
        unset files;
    fi

    if [ -f "estabs_${i}.parquet" ]; then
        clickhouse-local --query "SELECT * FROM file('estabs_${i}.parquet') WHERE situacao_cadastral LIKE '%2%' AND nome_fantasia IS NOT NULL AND nome_fantasia != '' INTO OUTFILE 'estabs_${i}_tratado.parquet' FORMAT Parquet SETTINGS output_format_parquet_compression_method = 'zstd'";
        rm estabs_${i}.parquet;
        mv estabs_${i}_tratado.parquet estabs_${i}.parquet;
    else
        echo "O arquivo estabs_${i}.parquet não foi encontrado, pulando.";
    fi
done

files=(*.parquet);
if [ -e "${files[0]}" ];then
    echo "Ao menos 1 arquivo foi encontrado, a seguir todos os arquivos .parquet desta pasta serão concatenados em 1 arquivo .parquet.";
    clickhouse-local --query "SELECT * FROM file('*.parquet') INTO OUTFILE 'estabs.parquet' FORMAT Parquet SETTINGS output_format_parquet_compression_method = 'zstd'";
    unset files;
fi

files=(*.ESTABELE);
if [ -e "${files[0]}" ];then
    echo "Ao menos 1 arquivo csv foi encontrado, apagando-o.";
    rm *.ESTABELE;
    unset files;
fi

files=(estabs_*.parquet);
if [ -e "${files[0]}" ];then
    echo "Ao menos 1 arquivo estabs_X.parquet foi encontrado, apagando-o.";
    rm estabs_*.parquet;
    unset files;
fi

