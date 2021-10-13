# OraBench - Release Notes

![Travis (.org)](https://img.shields.io/travis/KonnexionsGmbH/ora_bench.svg?branch=master)
![GitHub release](https://img.shields.io/github/release/KonnexionsGmbH/ora_bench.svg)
![GitHub Release Date](https://img.shields.io/github/release-date/KonnexionsGmbH/ora_bench.svg)
![GitHub commits since latest release](https://img.shields.io/github/commits-since/KonnexionsGmbH/ora_bench/1.2.0.svg)

----

## Version 1.2.0

Release Date: dd.mm.2021

### New Features

- Programming language [`Rust`](https://www.rust-lang.org) and database driver [`Rust-oracle`](https://github.com/kubo/rust-oracle)

### Applied Software

| Software              | Type     | Version           | Remark |
| ---                   | ---      | ---               | ---    |
| C++ (gcc)             | Language | 10.3.0            |   |
| cx_Oracle             | Driver   | 8.2.1             |   |
| Elixir                | Language | 1.12.3-otp-24     |   |
| Erlang                | Language | 24.1.2            |   |
| Go                    | Language | 1.17.2            |   |
| godror                | Driver   | v0.27.1           |   |
| JDBC.jl               | Driver   | v0.5.0            |   |
| Java                  | Language | openjdk-17        |   |
| Julia                 | Language | v1.6.3            |   |
| Kotlin                | Language | 1.5.31            |   |
| Oracle Instant Client | Driver   | 21.3.0.0.0        |   |
| Oracle JDBC           | Driver   | 21.3.0.0          |   |
| Oracle ODPI-C         | Driver   | 4.2.1             |   |
| Oracle.jl             | Driver   | v0.3.1            |   |
| oranif                | Driver   | 0.2.3             |   |
| Python 3              | Language | 3.10.0            |   |
| Rust                  | Language | 1.55.0            | new |
| Rust-oracle           | Driver   | v0.5.2            | new |

### Open issues

- C & ODPI-C: (see [here](#issues_c_odpi))
- Elixir & oranif: (see [here](#issues_elixir_oranif))
- Erlang & oranif: (see [here](#issues_erlang_oranif))
- Julia & JDBC,jl: (see [here](#issues_julia_jdbc))
- Julia & Oracle,jl: (see [here](#issues_julia_oracle))

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

### <a name="issues_elixir_oranif"></a> Elixir & oranif

#### Issue: Parameter `benchmark.core.multiplier` not properly supported:

##### `benchmark.core.multiplier=0`

    16:44:55.685 module=OraBench line=954  [info] Start ==========> trial no. 1
    16:44:55.809 module=OraBench line=670  [info] Start insert partition_key=1
    16:44:55.937 module=OraBench line=735  [info] End   insert partition_key=1
    16:44:55.937 module=OraBench line=670  [info] Start insert partition_key=2
    16:44:56.051 module=OraBench line=735  [info] End   insert partition_key=2
    16:44:56.051 module=OraBench line=670  [info] Start insert partition_key=3
    16:44:56.182 module=OraBench line=735  [info] End   insert partition_key=3
    16:44:56.182 module=OraBench line=670  [info] Start insert partition_key=4
    16:44:56.311 module=OraBench line=735  [info] End   insert partition_key=4
    16:44:56.311 module=OraBench line=670  [info] Start insert partition_key=5
    16:44:56.445 module=OraBench line=735  [info] End   insert partition_key=5
    16:44:56.445 module=OraBench line=670  [info] Start insert partition_key=6
    16:44:56.576 module=OraBench line=735  [info] End   insert partition_key=6
    16:44:56.576 module=OraBench line=670  [info] Start insert partition_key=7
    16:44:56.712 module=OraBench line=735  [info] End   insert partition_key=7
    16:44:56.712 module=OraBench line=670  [info] Start insert partition_key=8
    16:44:56.853 module=OraBench line=735  [info] End   insert partition_key=8
    16:44:56.853 module=OraBench line=670  [info] Start insert partition_key=9
    16:44:56.990 module=OraBench line=735  [info] End   insert partition_key=9
    16:44:56.990 module=OraBench line=670  [info] Start insert partition_key=10
    16:44:57.124 module=OraBench line=735  [info] End   insert partition_key=10

##### `benchmark.core.multiplier=1`

    16:47:57.949 module=OraBench line=954  [info] Start ==========> trial no. 1
    16:47:58.474 module=OraBench line=670  [info] Start insert partition_key=1
    16:47:58.580 module=OraBench line=735  [info] End   insert partition_key=1
    16:47:58.580 module=OraBench line=670  [info] Start insert partition_key=2
    16:47:58.686 module=OraBench line=735  [info] End   insert partition_key=2
    16:47:58.686 module=OraBench line=670  [info] Start insert partition_key=3
    16:47:58.817 module=OraBench line=735  [info] End   insert partition_key=3
    16:47:58.818 module=OraBench line=670  [info] Start insert partition_key=4
    16:47:58.946 module=OraBench line=735  [info] End   insert partition_key=4
    16:47:58.946 module=OraBench line=670  [info] Start insert partition_key=5
    16:47:59.067 module=OraBench line=735  [info] End   insert partition_key=5
    16:47:59.067 module=OraBench line=670  [info] Start insert partition_key=6
    16:47:59.192 module=OraBench line=735  [info] End   insert partition_key=6
    16:47:59.192 module=OraBench line=670  [info] Start insert partition_key=7
    16:47:59.316 module=OraBench line=735  [info] End   insert partition_key=7
    16:47:59.316 module=OraBench line=670  [info] Start insert partition_key=8
    16:47:59.446 module=OraBench line=735  [info] End   insert partition_key=8
    16:47:59.446 module=OraBench line=670  [info] Start insert partition_key=9
    16:47:59.574 module=OraBench line=735  [info] End   insert partition_key=9
    16:47:59.574 module=OraBench line=670  [info] Start insert partition_key=10
    16:47:59.705 module=OraBench line=735  [info] End   insert partition_key=10

### <a name="issues_erlang_oranif"></a> Erlang & oranif

#### Issue: Parameter `benchmark.core.multiplier` not properly supported:

##### `benchmark.core.multiplier=0`

    [orabench:run_trials:294] Start trial no 1
    Start insert partition_key=2
    Start insert partition_key=5
    Start insert partition_key=4
    Start insert partition_key=6
    Start insert partition_key=8
    Start insert partition_key=9
    Start insert partition_key=11
    Start insert partition_key=10
    Start insert partition_key=12
    Start insert partition_key=14
    Start insert partition_key=16
    Start insert partition_key=15
    Start insert partition_key=17
    Start insert partition_key=18
    Start insert partition_key=20
    Start insert partition_key=22
    Start insert partition_key=23
    Start insert partition_key=21
    Start insert partition_key=25
    Start insert partition_key=24

##### `benchmark.core.multiplier=1`

    [orabench:run_trials:294] Start trial no 1
    Start insert partition_key=2
    Start insert partition_key=3
    Start insert partition_key=5
    Start insert partition_key=6
    Start insert partition_key=7
    Start insert partition_key=9
    Start insert partition_key=10
    Start insert partition_key=11
    Start insert partition_key=15
    Start insert partition_key=14
    Start insert partition_key=16
    Start insert partition_key=12
    Start insert partition_key=17
    Start insert partition_key=19
    Start insert partition_key=22
    Start insert partition_key=20
    Start insert partition_key=18
    Start insert partition_key=24
    Start insert partition_key=25
    Start insert partition_key=23

### <a name="issues_julia_jdbc"></a> Julia & JDBC.jl

#### Issue: Batch operations not supported: `addBatch` & `executeBatch`

#### Issue: Windows 10 not supported:

    2021-10-11 17:14:43,808 [OraBench.java] INFO  Start OraBench.java
    2021-10-11 17:14:43,809 [OraBench.java] INFO  main() - number arguments=1
    2021-10-11 17:14:43,810 [OraBench.java] INFO  main() - 1st argument=setup_toml
    2021-10-11 17:14:43,884 [Config.java] INFO  benchmarkBatchSize      =0
    2021-10-11 17:14:43,885 [Config.java] INFO  benchmarkCoreMultiplier =0
    2021-10-11 17:14:43,885 [Config.java] INFO  benchmarkTransactionSize=0
    2021-10-11 17:14:43,886 [OraBench.java] INFO  Start Setup TOML OraBench Run
    2021-10-11 17:14:43,888 [OraBench.java] INFO  End   Setup TOML OraBench Run
    2021-10-11 17:14:43,888 [OraBench.java] INFO  End   OraBench.java
    Updating registry at `C:\Users\walte\.julia\registries\General`
    Updating git-repo `https://github.com/JuliaRegistries/General.git`
    -------------------------------------------------------------------------------
    The current time is: 17:14:52.55
    Enter the new time:
    -------------------------------------------------------------------------------
    End   lang\julia\scripts\run_bench_jdbc


### <a name="issues_julia_oracle"></a> Julia & Oracle.jl

#### Issue: Oracle.close: signal (11): Segmentation fault - [see here](https://github.com/felipenoris/Oracle.jl/issues/27)

    signal (11): Segmentation fault
    in expression starting at /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:605
    dpiConn__close at /home/walter/.julia/packages/Oracle/HDiQ4/deps/usr/lib/libdpi.so.4.1.0 (unknown line)
    dpiConn_close at /home/walter/.julia/packages/Oracle/HDiQ4/deps/usr/lib/libdpi.so.4.1.0 (unknown line)
    #dpiConn_close#5 at /home/walter/.julia/packages/Oracle/HDiQ4/src/odpi.jl:134 [inlined]
    dpiConn_close##kw at /home/walter/.julia/packages/Oracle/HDiQ4/src/odpi.jl:133 [inlined]
    #close#11 at /home/walter/.julia/packages/Oracle/HDiQ4/src/connection.jl:191
    close at /home/walter/.julia/packages/Oracle/HDiQ4/src/connection.jl:191
    _jl_invoke at /buildworker/worker/package_linux64/build/src/gf.c:2237 [inlined]
    jl_apply_generic at /buildworker/worker/package_linux64/build/src/gf.c:2419
    run_benchmark at /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:501
    main at /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:456
    unknown function (ip: 0x7f1a555fba7c)
    _jl_invoke at /buildworker/worker/package_linux64/build/src/gf.c:2237 [inlined]
    jl_apply_generic at /buildworker/worker/package_linux64/build/src/gf.c:2419
    jl_apply at /buildworker/worker/package_linux64/build/src/julia.h:1703 [inlined]
    do_call at /buildworker/worker/package_linux64/build/src/interpreter.c:115
    eval_value at /buildworker/worker/package_linux64/build/src/interpreter.c:204
    eval_stmt_value at /buildworker/worker/package_linux64/build/src/interpreter.c:155 [inlined]
    eval_body at /buildworker/worker/package_linux64/build/src/interpreter.c:562
    jl_interpret_toplevel_thunk at /buildworker/worker/package_linux64/build/src/interpreter.c:670
    jl_toplevel_eval_flex at /buildworker/worker/package_linux64/build/src/toplevel.c:877
    jl_eval_module_expr at /buildworker/worker/package_linux64/build/src/toplevel.c:195 [inlined]
    jl_toplevel_eval_flex at /buildworker/worker/package_linux64/build/src/toplevel.c:668
    jl_toplevel_eval_flex at /buildworker/worker/package_linux64/build/src/toplevel.c:825
    jl_toplevel_eval_in at /buildworker/worker/package_linux64/build/src/toplevel.c:929
    eval at ./boot.jl:360 [inlined]
    include_string at ./loading.jl:1116
    _jl_invoke at /buildworker/worker/package_linux64/build/src/gf.c:2237 [inlined]
    jl_apply_generic at /buildworker/worker/package_linux64/build/src/gf.c:2419
    _include at ./loading.jl:1170
    include at ./Base.jl:386
    _jl_invoke at /buildworker/worker/package_linux64/build/src/gf.c:2237 [inlined]
    jl_apply_generic at /buildworker/worker/package_linux64/build/src/gf.c:2419
    exec_options at ./client.jl:285
    _start at ./client.jl:485
    jfptr__start_34281 at /home/walter/.asdf/installs/julia/1.6.2/lib/julia/sys.so (unknown line)
    _jl_invoke at /buildworker/worker/package_linux64/build/src/gf.c:2237 [inlined]
    jl_apply_generic at /buildworker/worker/package_linux64/build/src/gf.c:2419
    jl_apply at /buildworker/worker/package_linux64/build/src/julia.h:1703 [inlined]
    true_main at /buildworker/worker/package_linux64/build/src/jlapi.c:560
    repl_entrypoint at /buildworker/worker/package_linux64/build/src/jlapi.c:702
    main at /buildworker/worker/package_linux64/build/cli/loader_exe.c:51
    __libc_start_main at /lib/x86_64-linux-gnu/libc.so.6 (unknown line)
    _start at /home/walter/.asdf/installs/julia/1.6.2/bin/julia (unknown line)
    Allocations: 70437479 (Pool: 70399537; Big: 37942); GC: 68
    ./lang/julia/scripts/run_bench_oracle_jl.sh: line 59: 16299 Segmentation fault      (core dumped) julia lang/julia/OraBenchOracle.jl priv/properties/ora_bench_toml.properties

#### Issue: @sync & @spawn or @threads: signal (11): Segmentation fault

    ┌ Info: Start trial no. 1
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:848
    ┌ Info: Start insert partition_key=8
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:602
    ┌ Info: Start insert partition_key=1
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:602
    ┌ Info: Start insert partition_key=2
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:602
    ┌ Info: Start insert partition_key=4
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:602
    ┌ Info: Start insert partition_key=6
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:602
    ┌ Info: Start insert partition_key=5
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:602
    ┌ Info: Start insert partition_key=7
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:602
    ┌ Info: Start insert partition_key=3
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:602
    ┌ Info: End   insert partition_key=8
    └ @ Main.OraBenchOracle /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:686
    
    signal (11): Segmentation fault
    in expression starting at /home/walter/Projects/ora_bench/lang/julia/OraBenchOracle.jl:942
    ./lang/julia/scripts/run_bench_oracle.sh: line 59: 20219 Segmentation fault      (core dumped) julia --threads 8 lang/julia/OraBenchOracle.jl priv/properties/ora_bench_toml.properties

#### Issue: Windows 10 not supported:

    2021-10-11 17:19:15,188 [OraBench.java] INFO  Start OraBench.java
    2021-10-11 17:19:15,189 [OraBench.java] INFO  main() - number arguments=1
    2021-10-11 17:19:15,189 [OraBench.java] INFO  main() - 1st argument=setup_toml
    2021-10-11 17:19:15,257 [Config.java] INFO  benchmarkBatchSize      =0
    2021-10-11 17:19:15,258 [Config.java] INFO  benchmarkCoreMultiplier =0
    2021-10-11 17:19:15,258 [Config.java] INFO  benchmarkTransactionSize=0
    2021-10-11 17:19:15,258 [OraBench.java] INFO  Start Setup TOML OraBench Run
    2021-10-11 17:19:15,260 [OraBench.java] INFO  End   Setup TOML OraBench Run
    2021-10-11 17:19:15,260 [OraBench.java] INFO  End   OraBench.java
    Updating registry at `C:\Users\walte\.julia\registries\General`
    Updating git-repo `https://github.com/JuliaRegistries/General.git`
    -------------------------------------------------------------------------------
    The current time is: 17:19:22.57
    Enter the new time:
    -------------------------------------------------------------------------------
    End   lang\julia\scripts\run_bench_oracle

