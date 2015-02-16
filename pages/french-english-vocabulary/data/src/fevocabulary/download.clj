(ns fevocabulary.download
  (:require [clj-http.client :as client])
  (:use [clojure.java.shell]
        [cascalog.api])
  (:import [java.io.File]
           [cascading.flow.hadoop HadoopFlowProcess]
           [cascading.operation ConcreteCall]))

(defn clean-filename [s]
  (let [ lower-s (clojure.string/lower-case s) ]
    (clojure.string/replace lower-s #"[^a-z]" "")))

(def cache-folder "cache/")
(def cache-file "cache")

(defn wiki-download-book [title lang]
  (let [filename (str cache-folder (clean-filename title) ".txt")
        l (if (= lang :french) "fr" "en")]
    (do
      (if (not (.exists (clojure.java.io/as-file cache-folder)))
        (.mkdir (java.io.File. cache-folder)))
      (if (not (.exists (clojure.java.io/as-file filename)))
        (spit filename  (:out (sh "vendor/tool/cli/book.php" "-t" title "-l" l)))))))

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
        (spit filename  (clean-text  (try
                          (:body (client/get (str gutenberg-mirror (num-to-url id true))
                                             {:as encoding}))
                          (catch Exception e (:body (client/get (str gutenberg-mirror (num-to-url id false))
                                                                {:as encoding}))))))))))

(defn download-book [id encoding source lang]
  (case source
    "gutenberg" (gutenberg-download-book id encoding)
    "wiki" (wiki-download-book id lang)))

(defn process-book [lang book]
  (let [encoding (if (:encoding book) (:encoding book) "UTF-8")
        source (if (:source book) (:source book) "gutenberg")
        id (:id book)]
    (do
      (println (str "Downloading: " (:title book)))
      (download-book id encoding source lang))))

(defn process-authors [lang authors]
    (map #(map (partial process-book lang)
               (:books (second %))) (first authors)))

(defprepfn lookup-filename [^HadoopFlowProcess a ^ConcreteCall b]
  (mapfn [] [ (let [filename (.getProperty a "cascading.source.path")]
                (.substring filename (inc (.lastIndexOf filename "/"))))]))

(defn get-text-and-filename [folder]
  (<- [!lines !file]
      ((hfs-textline folder) !lines)
      (lookup-filename :> !file)))

(defn download-all [in-file out-file]
  (doall
    (map #(process-authors
            (first %)
            (second %))
         (read-string (slurp in-file)))
    (?<- (hfs-seqfile out-file)
          [!line !filename]
          ((get-text-and-filename cache-file) !line !filename))

    ))


(defn wiki-find-book [title lang]
  (str (clean-filename title) ".txt"))

(defn gutenberg-find-book [id encoding]
  (str id ".txt"))

(defn find-book [id encoding source lang]
  (case source
    "gutenberg" (gutenberg-find-book id encoding)
    "wiki" (wiki-find-book id lang)))

(defn get-book-filename [lang book]
  (let [encoding (if (:encoding book) (:encoding book) "UTF-8")
        source (if (:source book) (:source book) "gutenberg")
        id (:id book)]
    (find-book id encoding source lang)))
