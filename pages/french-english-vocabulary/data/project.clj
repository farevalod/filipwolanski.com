(defproject fevocabulary "0.1.0-SNAPSHOT"
  :description "Compares the vocabulary of selected french and english authors"
  :url "http://example.com/FIXME"
  :jvm-opts ["-Xmx1024m" "-server" ]
  :plugins [[cider/cider-nrepl "0.7.0-SNAPSHOT"]]
  :source-paths ["src"]
  :repositories {"conjars" "http://conjars.org/repo"}
  :dependencies [[org.clojure/clojure "1.6.0"]
                 [org.clojure/data.json "0.2.4"]
                 [clojure-opennlp "0.3.2"]
                 [com.climate/claypoole "0.3.1"]
                 [com.atlascopco/hunspell-bridj "1.0.1"]
                 [cascalog "2.1.1" :exclusions [cascading/cascading-core
                                                cascading/cascading-hadoop]]
                 [clj-http "0.9.2"]
                 [cascading/cascading-hadoop2-mr1 "2.5.6"]
                 [cascading/cascading-local "2.5.6"]
                 [cascading/cascading-core "2.5.6"]]
  :main fevocabulary.core
  :target-path "build"
  :uberjar-name "fev.jar"
  :profiles {:uberjar {:aot :all}
             :provided { :dependencies
                        [[org.apache.hadoop/hadoop-mapreduce-client-jobclient "2.4.0"]
                         [org.apache.hadoop/hadoop-common "2.4.0"]]}})
