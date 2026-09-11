# cagedr: Access 'Novo CAGED' Microdata from the Brazilian Ministry of Labour

Download and read the public, non-identified microdata of the 'Novo
CAGED' (Cadastro Geral de Empregados e Desempregados), the monthly
registry of formal employment movements published by the Brazilian
Ministry of Labour and Employment through the 'PDET' FTP server
\<ftp://ftp.mtps.gov.br/pdet/microdados/\>. Lists the reference months
available on the server, downloads the three monthly files (movements
declared on time, declared late, and exclusions) with an idempotent
local cache, and reads the national '7z' archives as a stream, filtering
by state and selecting columns before anything is kept in memory, so
that a single state can be extracted without loading the full national
file. Also provides the official record layout and a helper to
consolidate admissions, separations and net balance by reference month.

## See also

Useful links:

- <https://github.com/StrategicProjects/cagedr>

- <https://strategicprojects.github.io/cagedr/>

- Report bugs at <https://github.com/StrategicProjects/cagedr/issues>

## Author

**Maintainer**: Andre Leite <leite@castlab.org>
([ORCID](https://orcid.org/0000-0002-4718-9766))

Authors:

- Andre Leite <leite@castlab.org>
  ([ORCID](https://orcid.org/0000-0002-4718-9766))

- Marcos Wasiliew <marcos.wasiliew@sepe.pe.gov.br>

- Hugo Vasconcelos <hugo.vasconcelos@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6249-0920))

- Carlos Amorim <carlos.agaf@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6315-8305))

- Diogo Bezerra <diogo.bezerra@ufpe.br>
  ([ORCID](https://orcid.org/0000-0002-1216-8674))

- Júlia Nascimento Barreto <juliabarreto@gd.seplag.pe.gov.br>
