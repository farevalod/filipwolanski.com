(ns fevocabulary.core
  (:require [clojure.data.json :as json]
            [cascalog.logic.ops :as c])
  (:use [fevocabulary.download :only [download-all]]
        [fevocabulary.write-example :only [write-example-json]]
        [fevocabulary.count-text :only [write-count-json]]
        [fevocabulary.unique :only [write-unique-json]]
        [fevocabulary.process-text :only [make-processed-text-file into-tuple]]
        [cascalog.api])
  (:gen-class))

(def in-file  "/opt/fev/texts.edn")
(def text-dir "/data/text-data")
(def processed-text-file "/data/processed-text")

(def unique-file "/opt/fev/unique.json")
(def words-file "/opt/fev/words.json")
(def example-file "/opt/fev/example.json")

(def unique-file-limit 250)

(def in-file-fields ["!lang" "!author" "!born" "!died" "!title" "!filename"])
(def in-file-source (name-vars (into-tuple in-file) in-file-fields))
(def processed-text-fields ["!lang" "!author" "!title" "!word" "!stem"])

(defn create-processed-text-source []
  (name-vars (hfs-seqfile processed-text-file) processed-text-fields))

(defn exit [status msg]
  (println msg)
  (System/exit status))

(defn -main [& args]
  (case (first args)
    "all" (do
            (write-example-json example-file)
            (make-processed-text-file processed-text-file text-dir in-file)
            (let [processed-source (create-processed-text-source)]
              (do
                (write-count-json processed-source in-file-source words-file)
                (write-unique-json processed-source in-file unique-file))))
    "example" (write-example-json example-file)
    "process" (make-processed-text-file processed-text-file text-dir in-file)
    "words" (write-count-json (create-processed-text-source) in-file-source words-file)
    "unique" (write-unique-json (create-processed-text-source) in-file unique-file unique-file-limit)
    "download" (download-all in-file text-dir)
    (exit "unknown option" 1)))

