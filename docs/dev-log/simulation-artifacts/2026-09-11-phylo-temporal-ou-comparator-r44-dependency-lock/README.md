# Rorqual comparator dependency lock

The first sealed comparator bundle used current CRAN transitive dependencies.
Its `Deriv` source required R 4.5, whereas Rorqual provides R 4.4.0. This
lock records the installed package closure used by the local paired comparator
pilot, then seals matching source versions for the next Rorqual provisioner.

It is a reproducibility repair for the campaign environment. It does not alter
the data-generating process, estimator, G13 interval verdict, or comparator
assessment target.
