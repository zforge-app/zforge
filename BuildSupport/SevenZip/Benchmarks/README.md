# Benchmark of the three integrations

The runner generates the two datasets and performs the same sequence ZIP Store (create/list/test/extract), with three repetitions and SHA-256 verification outside the measurement. Use a `.a` static build Release and dynamic build Release dylib in separate directories. Pass `--static-library`, `--dynamic-library` and a new `--output-dir` to `python3 run.py`.

Method, full command, results and limits: [7zip-linking.md](../../../Documentation/Benchmarks/7zip-linking.md). the temporary stages of the report identify local implementation; the runner finds the checkout by the file itself and accepts other paths for the compiled products.

`Adapter/` (ZF-25) compiles the same bridge-level (static and dynamic) and complete `ArchiveServing` harnesses from any number of source trees, so a HEAD export and the working tree can be compared A/B with the official CLI in rotated rounds. It also contains the in-process memory pipeline and helpers for xctrace/vmmap analysis. Commands and results: [7zip-adapter-optimization.md](../../../Documentation/Benchmarks/7zip-adapter-optimization.md#reproduction).
