# Results and limitations / 结果与局限

This is an undergraduate course/exploratory computational research project, **not** a peer-reviewed publication. Its manuscript examined four lunar regions using crater size–frequency distributions, Neukum model ages, Poisson Monte Carlo resampling and catalog-source comparisons. The figures and reported results in the original manuscript were **not** regenerated for this GitHub upload.

## Interpretation

- Model crater-count ages are not direct geochronological dates of returned samples.
- Catalog completeness and mixed geological units can cause major discrepancies, especially for young lunar basalt units around Chang'e-5.
- Catalog source selection, regional boundaries, diameter-fitting interval and model assumptions influence the result.
- This public code was recovered from the manuscript appendix, not independently checked against the original working project folder; MATLAB execution and reproduction testing are still outstanding.

## Reproducibility checklist

1. Obtain and license-check the LU1319373 source catalog, and verify columns/units.
2. Compare each extracted `.m` file with the original MATLAB project files.
3. Run `code/test_synthetic.m` and inspect model recovery.
4. Run `code/run_all.m` on the full catalog; compare generated figures and numbers with the report.
5. Record MATLAB release, input hashes, dependencies and validated output tables.

Do not cite this repository as a published, independently validated result.
