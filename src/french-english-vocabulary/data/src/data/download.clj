(ns data.download
  (:require [clj-http.client :as client])
  (:use clojure.java.shell)
  (:import java.io.File))

(defn clean-filename [s]
  (let [ lower-s (clojure.string/lower-case s) ]
    (clojure.string/replace lower-s #"[^a-z]" "")))

;; scraping to cache folder
(def cache-folder ".cache/")

(defn wiki-download-book [title lang]
  (let [filename (str cache-folder (clean-filename title) ".txt")
        l (if (= lang :french) "fr" "en")]
    (do
      (if (not (.exists (clojure.java.io/as-file cache-folder)))
        (.mkdir (java.io.File. cache-folder)))
      (if (not (.exists (clojure.java.io/as-file filename)))
        (spit filename  (:out (sh "vendor/tool/cli/book.php" "-t" title "-l" l))))
      (slurp filename))))

;; gutenberg scaping to cache folder

(def gutenberg-mirror "http://mirror.csclub.uwaterloo.ca/gutenberg/")
(def gutenberg-filter-regex #"[\*]+\s*(START|END) OF THIS PROJECT GUTENBERG.*")

(defn num-to-url [n alt]
  (str (apply str (interpose "/"
                             (into [] (subs (str n) 0 (dec (.length (str n))) ))))
       "/" (str n) "/" (str n) (if alt ".txt" "-8.txt")))

(defn clean-text [text]
  (let [split (clojure.string/split text gutenberg-filter-regex)]
    (apply max-key count split)))

(defn gutenberg-download-book [id encoding]
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


(defn download-book [id encoding source lang]
  (case source
    "gutenberg" (gutenberg-download-book id encoding)
    "wiki" (wiki-download-book id lang)))
