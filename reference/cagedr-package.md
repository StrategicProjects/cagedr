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

Authors:

- Andre Leite <leite@castlab.org>

- Marcos Wasilew <marcos.wasilew@gmail.com>

- Hugo Vasconcelos <hugo.vasconcelos@ufpe.br>

- Carlos Amorim <carlos.agaf@ufpe.br>

- Diogo Bezerra <diogo.bezerra@ufpe.br>
