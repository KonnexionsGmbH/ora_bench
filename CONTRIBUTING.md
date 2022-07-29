## OraBench - Contributing

In case of software changes we strongly recommend you to respect the license terms.

1. fork it
2. create your feature branch (`git checkout -b my-new-feature`)
3. commit your changes (`git commit -am 'Add some feature'`)
4. push to the branch (`git push origin my-new-feature`)
5. create a new pull request
6. Action points to be considered when adding a new database driver and / or a new programming language:
    - scripts
        - README.md
        - run_all_drivers.[bat|sh]
        - run_collect_and_compile.[bat|sh]
        - run_properties_[standard|variations].[bat|sh]
    - lang/\<language\>
    - README.md
    - Release-Notes.md
    - run_bench_all_dbs_props_[std|var].[bat|sh]
