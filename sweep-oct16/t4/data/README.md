750 CSVs are regenerable. From the drmTMB checkout root:

```sh
Rscript sweep-oct16/t4/t4_gen_data.R sweep-oct16/t4/data
```

Byte-identical given R ≥ 3.6.0 and `RNGkind("Mersenne-Twister", "Inversion", "Rejection")`.
`index.csv` is committed; the per-rep CSVs are not.
