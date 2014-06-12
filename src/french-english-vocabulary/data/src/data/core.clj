(ns data.core
  (:require [clojure.data.json :as json]
            [clj-http.client :as client]
            )
  (:use opennlp.nlp
        opennlp.tools.lazy)
  (:import java.io.File
           com.atlascopco.hunspell.Hunspell)
  (:gen-class))

(def output-file "words.json")
(def in-file "texts.edn")
(def http-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.114 Safari/537.36")
(def gutenberg-mirror "http://library.beau.org/gutenberg/")



(def text-directory "texts/")
(def folders {:english (str text-directory "english/")
              :french (str text-directory "french/")})

(def tokenizers
  {:english (make-tokenizer "models/en-token.bin")
   :french (make-tokenizer "models/fr-token.bin")})

(def stemmers
  {:english (Hunspell. "texts/english.dic" "texts/french.aff")
   :french (Hunspell. "texts/french.dic" "texts/french.aff")})

;; tokenization and counting
(defn remove-non-letters [s]
  (clojure.string/replace (clojure.string/lower-case  s) #"[^[:alpha:]]" ""))

(defn split-hyphenation [s]
    (clojure.string/split s #"-"))

(defn tokenize [text lang]
  (remove empty?
          (map remove-non-letters
               (mapcat split-hyphenation ((lang tokenizers) text)))))

(defn stem-and-unique [s lang]
  (distinct (map #(let [stem (.stem (lang stemmers) %)]
                    (if (empty? stem) % (first stem))) s)))

(defn process-file [file]
  (let [ lang (:lang file)
         text (slurp (:file file))
         tokens (tokenize text lang)]
    (conj (dissoc file :file) {:unique (distinct tokens)
                :unique-stems (stem-and-unique tokens lang)
                :word-count (count tokens) })))

(defn num-to-url [n alt]
  (str (apply str (interpose "/"
                             (into [] (subs (str n) 0 (dec (.length (str n))) ))))
       "/" (str n) "/" (str n) (if alt ".txt" "-8.txt")))

(defn download-book [id encoding]
  (try
    (:body (client/get (str gutenberg-mirror (num-to-url id true))
                       {:as encoding}))
    (catch Exception e (:body (client/get (str gutenberg-mirror (num-to-url id false))
                                          {:as encoding})))))

(defn process-book [lang book]
  (let [title (:title book)
        encoding (if (:encoding book) (:encoding book) "UTF-8")
        id (:id book)
        text (download-book id encoding)
        tokens (tokenize text lang)
        ]
  (hash-map :title title :word-count (count tokens) ))
  )

(defn read-authors [lang obj]
  (map (fn [[author props]]
          (let [books (map (partial process-book lang) (:books props))]
           (hash-map author {:books books})
            ))
       obj))

(defn read-input-file [file]
  (into {}
        (map #(hash-map (first %)
                        (into {} (mapcat (partial read-authors (first %)) (second %))) )
             (read-string (slurp file)))))



; (read-input-file in-file)

; (map analyze-author (partition-by :author (take 3 (read-folders folders))))




(defn -main
  [& args]
  (spit output-file
        (json/write-str (read-input-file in-file))))
