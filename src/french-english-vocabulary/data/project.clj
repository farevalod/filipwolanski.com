(defproject data "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :plugins [[cider/cider-nrepl "0.7.0-SNAPSHOT"]]
  :dependencies [[org.clojure/clojure "1.5.1"]
                 [org.clojure/data.json "0.2.4"]
                 [clojure-opennlp "0.3.2"]
                 [com.atlascopco/hunspell-bridj "1.0.1"]
                 [clj-http "0.9.2"]
                 ]
  :main ^:skip-aot data.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
