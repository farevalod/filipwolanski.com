(ns data.core
  (:require [clojure.data.json :as json]
            [clj-http.client :as client]
            )
  (:use opennlp.nlp
        opennlp.tools.lazy)
  (:import java.io.File
           com.atlascopco.hunspell.Hunspell)
  (:gen-class))



;; tokenization and counting

(def tokenizers
  {:english (make-tokenizer "models/en-token.bin")
   :french (make-tokenizer "models/fr-token.bin")})

(def stemmers
  {:english (Hunspell. "models/en.dic" "models/en.aff")
   :french (Hunspell. "models/fr.dic" "models/fr.aff")})

(defn remove-punctuation [s]
  (let [ lower-s (clojure.string/lower-case s) ]
    (clojure.string/replace lower-s #"[^a-z']" "")))


(defn split-hyphenation [s]
    (clojure.string/split s #"-"))

(defn tokenize [text lang]
  (remove empty?
          (map remove-punctuation
               (mapcat split-hyphenation ((lang tokenizers) text)))))

(defn stem-and-unique [s lang]
  (distinct (map #(let [stem (.stem (lang stemmers) %)]
                    (if (empty? stem) % (apply min-key count stem))) s)))

; (apply min-key count (.stem (:english stemmers) "was" ))


;; gutenberg scaping to cache folder

(def cache-folder ".cache/")
(def gutenberg-mirror "http://mirror.csclub.uwaterloo.ca/gutenberg/")
(def gutenberg-filter-regex #"[\*]+\s*(START|END) OF THIS PROJECT GUTENBERG.*")

(defn num-to-url [n alt]
  (str (apply str (interpose "/"
                             (into [] (subs (str n) 0 (dec (.length (str n))) ))))
       "/" (str n) "/" (str n) (if alt ".txt" "-8.txt")))

(defn clean-text [text]
  (let [split (clojure.string/split text gutenberg-filter-regex)]
    (apply max-key count split)))

(defn download-book [id encoding]
  (let [filename (str cache-folder id ".txt")]
    (do
      (if (not (.exists (clojure.java.io/as-file cache-folder)))
        (.mkdir (java.io.File. cache-folder)))
      (if (not (.exists (clojure.java.io/as-file filename)))
        (spit filename  (try
                          (:body (client/get (str gutenberg-mirror (num-to-url id true))
                                             {:as encoding}))
                          (catch Exception e (:body (client/get (str gutenberg-mirror (num-to-url id false))
                                                                {:as encoding}))))))
      (clean-text (slurp filename)))))

;; processing

(def output-file "words.json")
(def in-file "texts.edn")

(defn process-book [lang book]
  (let [title (:title book)
        encoding (if (:encoding book) (:encoding book) "UTF-8")
        id (:id book)
        text (download-book id encoding)
        tokens (tokenize text lang)
        dtokens (distinct tokens)
        stemmed (stem-and-unique dtokens lang)]
    (do
      (println (str "Processing " title))
      (hash-map :title title
                :word-count (count tokens)
                :distinct-tokens dtokens
                :distinct-stems stemmed
                :distinct-token-count (count dtokens)
                :distinct-stem-count (count stemmed) ))))

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


; (spit output-file (json/write-str  (read-string (slurp in-file))))

(defn -main
  [& args]
  (do (time (spit output-file
                    (json/write-str (read-input-file in-file))))
      (shutdown-agents)))
