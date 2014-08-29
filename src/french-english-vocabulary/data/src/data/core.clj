(ns data.core
  (:require [clojure.data.json :as json])
  (:use [data.download :only [download-book ]]
        [data.stem :only [tokenize stem]])
  (:gen-class))


;; tokenization and counting

(def limit 5000)

(def output-file "words.json")
(def in-file "texts.edn")

(defn stem-and-unique [s lang]
  (distinct (filter not-empty (stem s lang))))

(defn process-book [lang book]
  (let [title (:title book)
        encoding (if (:encoding book) (:encoding book) "UTF-8")
        source (if (:source book) (:source book) "gutenberg")
        id (:id book)
        text (download-book id encoding source lang)
        tokens (tokenize text lang)
        dtokens (distinct tokens)
        stemmed (stem-and-unique dtokens lang)
        l-tokens (take limit tokens)
        l-dtokens (distinct l-tokens)
        l-stemmed (stem-and-unique l-dtokens lang)
        ]
    (do
      (println (str "Processing " title))
      (hash-map :title title
                :word-count (count tokens)
                :distinct-tokens dtokens
                :distinct-stems stemmed
                :distinct-token-count (count dtokens)
                :distinct-stem-count (count stemmed)
                :limited-token-count (count l-dtokens)
                :limited-stem-count (count l-stemmed)))))

; (process-book :english {:title "temp" :id 86 })

(defn read-authors [lang obj]
  (map (fn [[author props]]
          (let [books (map (partial process-book lang) (:books props))
                dtokens (mapcat #(:distinct-tokens %) books)
                stems (mapcat #(:distinct-stems %) books)
                nbooks (map #(dissoc % :distinct-tokens :distinct-stems) books)
                words (reduce + (map #(:word-count %) books))]
           (hash-map author {:dates (:dates props)
                             :books nbooks
                             :distinct-token-count (count (distinct dtokens))
                             :distinct-stem-count (count (distinct stems))
                             :word-count words
                             })))
       obj))

(defn pmapcat [f batches]
  (->> batches
       (pmap f)
       (apply concat)
       doall))

(defn read-input-file [file]
  (into {}
        (map #(hash-map (first %)
                        (into {} (pmapcat (partial read-authors (first %)) (second %))) )
             (read-string (slurp file)))))


(defn -main
  [& args]
  (do (time (spit output-file (str "words = "
                    (json/write-str (read-input-file in-file)) ";")))
      (shutdown-agents)))
