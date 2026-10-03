# Benchmark das três integrações

O runner gera os dois datasets e executa a mesma sequência ZIP Store (criar/listar/testar/extrair), com três repetições e verificação SHA-256 fora da medição. Use uma `.a` da build Release estática e a dylib da build Release dinâmica em diretórios separados. Passar `--static-library`, `--dynamic-library` e um `--output-dir` novo para `python3 run.py`.

Método, comando completo, resultados e limites: [7zip-linking.md](../../../Documentation/Benchmarks/7zip-linking.md). Os paths temporários do relatório identificam a execução local; o runner encontra o checkout pelo próprio arquivo e aceita outros paths para os produtos compilados.
