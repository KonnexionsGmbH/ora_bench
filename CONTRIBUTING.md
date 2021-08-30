## OraBench - Contributing 

In case of software changes we strongly recommend you to respect the license terms.

1. fork it
1. create your feature branch (`git checkout -b my-new-feature`)
1. commit your changes (`git commit -am 'Add some feature'`)
1. push to the branch (`git push origin my-new-feature`)
1. create a new pull request
1. Action points to be considered when adding a new database driver and / or a new programming language:
   - scripts
     - README.md
     - run_bench_all_drivers.[bat|sh]
     - run_collect_and_compile.[bat|sh]
     - run_properties_[standard|variations].[bat|sh]
   - lang/\<langauge\>
   - README.md
   - Release-Notes.md
   - run_bench_all_dbs_props_[std|var].[bat|sh]
