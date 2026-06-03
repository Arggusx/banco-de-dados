import io
import csv
import time
import random
import hashlib

from faker import Faker
import psycopg2
import pandas as pd

DB_CONFIG = {
    "host":     "localhost",
    "port":     5432,
    "dbname":   "ecommerce_atividade",    
    "user":     "postgres",        
    "password": "12345678",       
}

TOTAL_USUARIOS  = 25_000
TOTAL_ENDERECOS = 25_000
TOTAL_PERFIS    = 5_000    
TOTAL_PAISES    = 5_000   

fake = Faker("pt_BR")
Faker.seed(42)          
random.seed(42)


def gerar_senha_hash(texto: str) -> str:
    return hashlib.sha256(texto.encode("utf-8")).hexdigest()


def gerar_usuarios(qtd: int) -> pd.DataFrame:
    print(f"[1/4] Gerando {qtd:,} usuários com Faker (pt_BR)...")
    inicio = time.time()

    emails_unicos = set()
    registros = []

    while len(registros) < qtd:
        nome  = fake.name()
        email = fake.unique.email()

        if email in emails_unicos:
            continue
        emails_unicos.add(email)

        perfil_id = random.randint(1, TOTAL_PERFIS)
        senha     = gerar_senha_hash(fake.password(length=12))

        registros.append({
            "perfil_id": perfil_id,
            "nome":      nome,
            "email":     email,
            "senha":     senha,
        })

    elapsed = time.time() - inicio
    print(f"      ✔ {len(registros):,} usuários gerados em {elapsed:.2f}s")

    return pd.DataFrame(registros)


def gerar_enderecos(qtd: int) -> pd.DataFrame:
    print(f"[2/4] Gerando {qtd:,} endereços com Faker (pt_BR)...")
    inicio = time.time()

    registros = []
    for i in range(1, qtd + 1):
        registros.append({
            "usuario_id": i,
            "pais_id":    random.randint(1, TOTAL_PAISES),
            "rua":        fake.street_address(),
            "cidade":     fake.city(),
        })

    elapsed = time.time() - inicio
    print(f"      ✔ {len(registros):,} endereços gerados em {elapsed:.2f}s")

    return pd.DataFrame(registros)


def dataframe_para_csv_buffer(df: pd.DataFrame) -> io.StringIO:
    buffer = io.StringIO()
    df.to_csv(buffer, index=False, header=False, quoting=csv.QUOTE_MINIMAL)
    buffer.seek(0)
    return buffer


def bulk_insert_copy(cursor, tabela: str, colunas: list, buffer: io.StringIO):
    cols = ", ".join(colunas)
    sql  = f"COPY {tabela} ({cols}) FROM STDIN WITH (FORMAT csv, DELIMITER ',')"
    cursor.copy_expert(sql, buffer)


def limpar_tabelas(cursor):
    print("[0/4] Limpando tabelas (TRUNCATE ... RESTART IDENTITY CASCADE)...")
    cursor.execute("""
        TRUNCATE TABLE enderecos, usuarios
        RESTART IDENTITY CASCADE;
    """)
    print("      ✔ Tabelas 'usuarios' e 'enderecos' limpas com sucesso.")


def main():
    print("=" * 70)
    print(" GERADOR DE DADOS REALISTAS — Faker pt_BR + PostgreSQL (COPY)")
    print("=" * 70)
    print()

    print(f"Conectando ao banco '{DB_CONFIG['dbname']}' "
          f"em {DB_CONFIG['host']}:{DB_CONFIG['port']}...")
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False
    cursor = conn.cursor()
    print("      ✔ Conexão estabelecida.\n")

    try:
        limpar_tabelas(cursor)
        print()

        df_usuarios  = gerar_usuarios(TOTAL_USUARIOS)
        df_enderecos = gerar_enderecos(TOTAL_ENDERECOS)
        print()

        print("[3/4] Convertendo DataFrames para buffers CSV...")
        buf_usuarios  = dataframe_para_csv_buffer(df_usuarios)
        buf_enderecos = dataframe_para_csv_buffer(df_enderecos)
        print("      ✔ Buffers prontos.\n")

        print("[4/4] Inserindo dados via COPY (Bulk Insert)...")
        inicio = time.time()

        bulk_insert_copy(
            cursor, "usuarios",
            ["perfil_id", "nome", "email", "senha"],
            buf_usuarios
        )
        print(f"      ✔ {TOTAL_USUARIOS:,} usuários inseridos.")

        bulk_insert_copy(
            cursor, "enderecos",
            ["usuario_id", "pais_id", "rua", "cidade"],
            buf_enderecos
        )
        print(f"      ✔ {TOTAL_ENDERECOS:,} endereços inseridos.")

        elapsed = time.time() - inicio
        print(f"      ✔ Bulk Insert concluído em {elapsed:.2f}s\n")

        conn.commit()
        print("✔ COMMIT realizado com sucesso.")

        print("\n" + "=" * 70)
        print(" VALIDAÇÃO — Contagem de registros inseridos")
        print("=" * 70)

        cursor.execute("SELECT COUNT(*) FROM usuarios;")
        total_u = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM enderecos;")
        total_e = cursor.fetchone()[0]

        print(f"  → usuarios:  {total_u:,} registros")
        print(f"  → enderecos: {total_e:,} registros")
        print(f"  → TOTAL:     {total_u + total_e:,} registros")

        print("\n" + "-" * 70)
        print(" AMOSTRA — 5 primeiros usuários")
        print("-" * 70)
        cursor.execute("SELECT id, nome, email FROM usuarios ORDER BY id LIMIT 5;")
        for row in cursor.fetchall():
            print(f"  ID {row[0]:>5} | {row[1]:<40} | {row[2]}")

        print("\n" + "-" * 70)
        print(" AMOSTRA — 5 primeiros endereços")
        print("-" * 70)
        cursor.execute(
            "SELECT id, usuario_id, rua, cidade FROM enderecos ORDER BY id LIMIT 5;"
        )
        for row in cursor.fetchall():
            print(f"  ID {row[0]:>5} | Usr {row[1]:>5} | {row[2]:<45} | {row[3]}")

    except Exception as e:
        conn.rollback()
        print(f"\n✘ ERRO: {e}")
        print("  ROLLBACK realizado. Nenhum dado foi persistido.")
        raise

    finally:
        cursor.close()
        conn.close()
        print("\n✔ Conexão encerrada.")
        print("=" * 70)
        print(" Próximo passo: execute o script DML-parte2.sql.")
        print("=" * 70)


if __name__ == "__main__":
    main()
