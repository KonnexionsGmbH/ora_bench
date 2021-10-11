# OraBench - Release Notes

![Travis (.org)](https://img.shields.io/travis/KonnexionsGmbH/ora_bench.svg?branch=master)
![GitHub release](https://img.shields.io/github/release/KonnexionsGmbH/ora_bench.svg)
![GitHub Release Date](https://img.shields.io/github/release-date/KonnexionsGmbH/ora_bench.svg)
![GitHub commits since latest release](https://img.shields.io/github/commits-since/KonnexionsGmbH/ora_bench/1.1.0.svg)

----

## Version 1.1.0

Release Date: 11.10.2021

### New Features

- Oracle Database 21c
- Programming language [`Julia`](https://julialang.org) and database driver [`JDBC.jl`](https://github.com/JuliaDatabases/JDBC.jl)
- Programming language [`Julia`](https://julialang.org) and database driver [`Oracle.jl`](https://github.com/felipenoris/Oracle.jl)

### Applied Software

| Software              | Type     | Version           | Remark |
| ---                   | ---      | ---               | ---    |
| C++ (gcc)             | Language | 10.3.0            | upgrade |
| Elixir                | Language | 1.12.3-otp-24     | upgrade |
| Erlang                | Language | 24.1.2            | upgrade |
| Go                    | Language | 1.17.2            | upgrade |
| godror                | Driver   | v0.27.1           | upgrade |
| Java                  | Language | openjdk-17        | upgrade |
| JDBC.jl               | Driver   | v0.5.0            | new |
| Julia                 | Language | v1.6.3            | new |
| Kotlin                | Language | 1.5.31            | upgrade |
| Oracle cx_Oracle      | Driver   | 8.2.1             |   |
| Oracle Instant Client | Driver   | 21.3.0.0.0        | upgrade |
| Oracle JDBC           | Driver   | 21.3.0.0          | upgrade |
| Oracle ODPI-C         | Driver   | 4.2.1             |   |
| Oracle.jl             | Driver   | v0.3.1            | new |
| oranif                | Driver   | 0.2.3             |   |
| Python 3              | Language | 3.10.0            | upgrade |

### Open issues

- C & ODPI-C: (see [here](#issues_c_odpi))
- Elixir & oranif: (see [here](#issues_elixir_oranif))
- Erlang & oranif: (see [here](#issues_erlang_oranif))
- Julia & JDBC,jl: (see [here](#issues_julia_jdbc))
- Julia & Oracle,jl: (see [here](#issues_julia_oracle))

----

## Windows 10 Performance Snapshot

The finishing touch to the work on a new release is a test run with all databases under identical conditions on three different systems - Ubuntu 20.04 via VMware and WSL2, Windows 10.
The measured time includes the total time required for the DDL effort (database, schema, user, 5 database tables) and the DML effort (insertion of 7011 rows).
The hardware used includes an AMD Ryzen 9 5950X CPU with 128GB RAM.
The tests run exclusively on the computer in each case.
The detailed results can be found in the DBSeeder repository in the `resources/statistics` directory.

The following table shows the results of the Windows 10 run.
If the database can run with both activated and deactivated constraints (foreign, primary and unique key), the table shows the better value and in the column `Improvement` the relative value to the worse run.
For example, the MonetDB database is faster with inactive constraints by 21.2% compared to the run with activated constraints.

![](.README_images/Statistics_9.9.9_win10.png)

- **DBMS** - official DBMS name
- **Type** - client version, embedded version or via trino
- **ms** - total time of DDL and DML operations in milliseconds
- **Constraints** - DML operations with active or inactive constraints (foreign, primary and unique key)
- **Improvement** - improvement of total time if constraints are inactive

----

## Detailed Open Issues

### <a name="issues_c_odpi"></a> C & ODPI-C

#### Issue: Ubuntu 20.04: compile errors

```
    rm -rf ./*.obj
    rm -rf ./OraBench
    gcc -o OraBench -Ilang/c -I"lang/c/odpi/include" -O2 -ggdb -Wall -fPIC -std=gnu11 -DEMBED lang/c/odpis.c lang/c/config.c lang/c/OraBench.c -lpthread -ldl 
    In file included from lang/c/odpi/include/../embed/dpi.c:27,
                     from lang/c/odpis.c:7:
    lang/c/odpi/include/../embed/../src/dpiError.c: In function ‘dpiError__setFromOS’:
    lang/c/odpi/include/../embed/../src/dpiError.c:264:13: warning: assignment to ‘char *’ from ‘int’ makes pointer from integer without a cast [-Wint-conversion]
      264 |     message = strerror_r(err, buffer, sizeof(buffer));
          |             ^
    In file included from lang/c/odpi/include/../embed/dpi.c:38,
                     from lang/c/odpis.c:7:
    lang/c/odpi/include/../embed/../src/dpiOci.c: In function ‘dpiOci__loadLibInModuleDir’:
    lang/c/odpi/include/../embed/../src/dpiOci.c:1856:5: error: unknown type name ‘Dl_info’
     1856 |     Dl_info info;
          |     ^~~~~~~
    lang/c/odpi/include/../embed/../src/dpiOci.c:1858:9: warning: implicit declaration of function ‘dladdr’ [-Wimplicit-function-declaration]
     1858 |     if (dladdr(dpiContext_createWithParams, &info) != 0) {
          |         ^~~~~~
    lang/c/odpi/include/../embed/../src/dpiOci.c:1860:56: error: request for member ‘dli_fname’ in something not a structure or union
     1860 |             dpiDebug__print("module name is %s\n", info.dli_fname);
          |                                                        ^
    lang/c/odpi/include/../embed/../src/dpiOci.c:1861:31: error: request for member ‘dli_fname’ in something not a structure or union
     1861 |         dirName = strrchr(info.dli_fname, '/');
          |                               ^
    lang/c/odpi/include/../embed/../src/dpiOci.c:1863:59: error: request for member ‘dli_fname’ in something not a structure or union
     1863 |             return dpiOci__loadLibWithDir(loadParams, info.dli_fname,
          |                                                           ^
    lang/c/odpi/include/../embed/../src/dpiOci.c:1864:45: error: request for member ‘dli_fname’ in something not a structure or union
     1864 |                     (size_t) (dirName - info.dli_fname), 0, error);
          |                                             ^
    make: *** [lang/c/Makefile:30: OraBench] Error 1
```

#### Issue: Windows 10: no reaction

```
    Start OraBench.c
    argv[1]=priv\properties\ora_bench_c.properties
```
